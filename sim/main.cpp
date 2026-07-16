#include <cstdint> 
#include <string>
#include <vector>
#include <cstring>
#include <cstdio>
const int MSG_LENGTH = 10;

typedef uint8_t mt_t;
typedef uint8_t side_t;
typedef uint32_t price_t;
typedef uint32_t orsize_t;
typedef std::vector<uint8_t> msg;


msg create_msg(
    mt_t messagetype,
    side_t side,
    price_t price,
    orsize_t size
) {
    msg returnvector;
    returnvector.reserve(MSG_LENGTH);
    returnvector.push_back(messagetype);
    returnvector.push_back(side);

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

void serialize(
    msg message
) {
    for (int i = 0; i < MSG_LENGTH; i++) {
        printf("%02x\n", message[i]);
    }
}

int main() {
    return 0;
}