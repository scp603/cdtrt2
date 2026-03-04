#pragma once
#include <string>
#include <vector>  // For Base64 encoding/decoding

static const char ENCODING_TABLE[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

std::string base64_encode(const std::string& data) {
	std::string encoded;
	int val = 0, valb = -6;
	for (char c : data) {
		val = (val << 8) + c;
		valb += 8;
		while (valb >= 0) {
			encoded.push_back(ENCODING_TABLE[(val >> valb) & 0x3F]);
			valb -= 6;
		}
	}
	if (valb > -6) encoded.push_back(ENCODING_TABLE[((val << 8) >> (valb + 8)) & 0x3F]);

	// Ensure proper padding
	while (encoded.size() % 4) encoded.push_back('=');

	return encoded;
}

// Base64 decoding function (FIXED)
std::string base64_decode(const std::string& encoded) {
	std::string decoded;
	std::vector<int> T(256, -1);
	for (int i = 0; i < 64; i++) T[ENCODING_TABLE[i]] = i;

	int val = 0, valb = -8;
	for (char c : encoded) {
		if (T[c] == -1) break;
		val = (val << 6) + T[c];
		valb += 6;
		if (valb >= 0) {
			decoded.push_back(char((val >> valb) & 0xFF));
			valb -= 8;
		}
	}
	return decoded;
}