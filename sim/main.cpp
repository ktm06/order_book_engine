#include <windows.h>
#include <cstdint> 
#include <string>
#include <vector>
#include <cstring>
#include <cstdio>
#include <unordered_map>
#include <optional>

const int MSG_LENGTH = 10;
const char* PORT_NAME = "placeholder";
const int BAUD_RATE = 115200 ;

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
    std::string messagetype,
    std::string side,
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

void send_uart(HANDLE h, const msg& message) {
    DWORD written;
    if (!WriteFile(h, message.data(), message.size(), &written, NULL)
    || written != message.size()) {
        fprintf(stderr, "UART write failed (%lu/%zu bytes)\n", written, message.size());
        exit(1);
    }
}

int main() {

    HANDLE hSerial;
    
    hSerial = CreateFile(PORT_NAME,
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
        fprintf(stderr, "Error setting serial port state\n");
        CloseHandle(hSerial);
        return 1;
    }

    send_uart(hSerial, create_msg("ADD", "ASK", 50, 10));

    CloseHandle(hSerial);

    return 0;
}