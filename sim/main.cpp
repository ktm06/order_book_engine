#include <windows.h>
#include <cstdint> 
#include <string>
#include <vector>
#include <cstring>
#include <cstdio>
#include <unordered_map>
#include <optional>

const int MSG_LENGTH = 10;
const char* PORT_NAME = "\\\\.\\COM3";;

typedef uint8_t mt_t;
typedef uint8_t side_t;
typedef uint32_t price_t;
typedef uint32_t orsize_t;
typedef std::vector<uint8_t> msg;
/*  localparam [7:0]
    ASK = 8'd0,
    BID = 8'd1;

    localparam[7:0]
    ADD = 8'h01,
    DEL = 8'h02,
    MOD = 8'h03;
*/
const std::unordered_map<std::string, uint8_t> instr_to_byte = {
    {{"ASK", 0x0}, {"BID", 0x1}, {"ADD", 0x1}, {"DEL", 0x2}, {"MOD", 0x3}}
};

std::optional<uint8_t> convert_instr(
    std::string instr
) {
    // handle bad instr
    auto it = instr_to_byte.find(instr);
    if (it != instr_to_byte.end()) {
        return it->second;
    }

    return std::nullopt;
}

msg create_msg(
    const char* messagetype,
    const char* side,
    price_t price,
    orsize_t size
) {
    msg returnvector;
    auto dec_messagetype = convert_instr(messagetype);

    if (dec_messagetype) {
        returnvector.push_back(*dec_messagetype);
    } else {
        returnvector.push_back(0xFF); //default bad instr bit
        printf("bad instruction!");
    }

    auto dec_side = convert_instr(side);

    if (dec_side) {
        returnvector.push_back(*dec_side);
    } else {
        returnvector.push_back(0xFF);
        printf("bad instruction!");
    }

    uint8_t price_bytes[4];
    std::memcpy(price_bytes, &price, sizeof(price));

    for (int i = 0; i < sizeof(price_bytes); i++) {
        returnvector.push_back(price_bytes[3-i]);
    }

    uint8_t size_bytes[4];
    std::memcpy(size_bytes, &size, sizeof(size));
    for (int i = 0; i < sizeof(size_bytes); i++) {
        returnvector.push_back(size_bytes[3-i]);
    }

    return returnvector;
}

// later usage  
void serialize(
    msg message
) {
    for (int i = 0; i < MSG_LENGTH; i++) {
        printf("%02x\n", message[i]);
    }
}

bool send_uart(HANDLE h, const msg& message) {
    DWORD written = 0;

    BOOL uart_write = WriteFile(
        h,
        message.data(),
        message.size(),
        &written,
        NULL
    );

    if (!uart_write) {
        fprintf(stderr, "FAIL: fail uart write. windows error %lu\n", GetLastError());

        return false;
    }

    if (written != message.size()) {
        fprintf(stderr, "FAIL: uart incomplete write %lu/%zu bytes\n", written, message.size());
        return false;
    }

    return true;
}

std::optional<uint32_t> read_spread(HANDLE h) {
    uint8_t buf[4] = {};
    DWORD received = 0;

    // ensure size match1
    if (!ReadFile(h, buf, 4, &received, NULL)) {
        fprintf(stderr, "FAIL: readfile fail error, windows error: %lu", GetLastError());
        return std::nullopt;
    }
    if (received != 4){
        fprintf(stderr, "FAIL: reply timeout, %lu/4 bytes\n", received);
        PurgeComm(h, PURGE_RXCLEAR);
        return std::nullopt;
    }
   
    // into one
    return ((uint32_t)buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | (buf[3]);
}


void ut(
    HANDLE h,
    const char* messagetype,
    const char* side,
    price_t price,
    orsize_t size,
    uint32_t expected
) {
    msg message = create_msg(messagetype, side, price, size);

    if (!send_uart(h, message)) {
        printf("FAIL: could not send mt=%s, side=%s, price=%u, size=%u\n",
               messagetype, side, price, size);
        return;
    }

    auto response = read_spread(h);

    if (!response) {
        printf("FAIL: no response for mt=%s, side=%s, price=%u, size=%u\n",
               messagetype, side, price, size);
        return;
    }

    uint32_t actual = *response;

    if (actual == expected) {
        printf("PASS: mt=%s, side=%s, price=%u, size=%u, spread=%u\n",
               messagetype, side, price, size, actual);
    } else {
        printf("FAIL: mt=%s, side=%s, price=%u, size=%u, expected=%u, actual=%u\n",
               messagetype, side, price, size, expected, actual);
    }
    Sleep(2); // gap
}

int main() {

    HANDLE hSerial;
    
    hSerial = CreateFileA(PORT_NAME,
                        GENERIC_READ | GENERIC_WRITE,
                        0,
                        0,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        0);


    if (hSerial == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "Error opening COM port\n");
        return 1;
    }
    
    
    DCB dcbSerialParams = {0};
    dcbSerialParams.DCBlength = sizeof(dcbSerialParams);

    if (!GetCommState(hSerial, &dcbSerialParams)) {
        fprintf(stderr, "Error getting state\n");
        CloseHandle(hSerial);
        return 1;
    }

    // set handshake
    dcbSerialParams.BaudRate = CBR_115200;
    dcbSerialParams.ByteSize=8;
    dcbSerialParams.StopBits = ONESTOPBIT;
    dcbSerialParams.Parity = NOPARITY;
    if (!SetCommState(hSerial, &dcbSerialParams)) {
        fprintf(stderr, "Error setting state\n");
        CloseHandle(hSerial);
        return 1;
    }


   COMMTIMEOUTS timeouts = {};
    timeouts.ReadIntervalTimeout = 50;
    timeouts.ReadTotalTimeoutConstant = 1000;
    timeouts.ReadTotalTimeoutMultiplier = 0;
    timeouts.WriteTotalTimeoutConstant = 1000;
    timeouts.WriteTotalTimeoutMultiplier = 0;

    if (!SetCommTimeouts(hSerial, &timeouts)) {
        fprintf(stderr, "Error setting timeouts: %lu\n", GetLastError());
        CloseHandle(hSerial);
        return 1;
    }

    PurgeComm(hSerial, PURGE_RXCLEAR | PURGE_TXCLEAR);
    printf("Pprt open, wait for input\n");
    getchar();

    ut(hSerial, "ADD", "ASK", 50, 10, 0);
    ut(hSerial, "ADD", "ASK", 55, 10, 0);
    ut(hSerial, "ADD", "ASK", 60, 10, 0);
    ut(hSerial, "ADD", "BID", 40, 10, 10);
    ut(hSerial, "ADD", "BID", 45, 10, 5);
    ut(hSerial, "ADD", "BID", 45, 20, 5);
    ut(hSerial, "DEL", "BID", 45, 30, 10);
    ut(hSerial, "DEL", "ASK", 50, 10, 15);
    ut(hSerial, "MOD", "ASK", 55, 99, 15);
    ut(hSerial, "DEL", "ASK", 12345, 5, 15);
    ut(hSerial, "ADD", "BID", 41, 10, 14);
    ut(hSerial, "ADD", "BID", 42, 10, 13);
    ut(hSerial, "ADD", "BID", 43, 10, 12);
    ut(hSerial, "ADD", "BID", 44, 10, 11);
    ut(hSerial, "ADD", "BID", 1, 10, 11);

    printf("Finished");
    CloseHandle(hSerial);

    return 0;
}