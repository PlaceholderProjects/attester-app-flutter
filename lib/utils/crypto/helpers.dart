import 'dart:convert';

import 'package:bs58/bs58.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:placeholder/utils/crypto/polkadot.dart';
import 'package:placeholder/utils/crypto/solana.dart';
import 'package:reown_appkit/reown_appkit.dart';

// import 'package:solana_web3/solana_web3.dart' as solana;

import '../test_data.dart';
import 'eip155.dart';

List<String> getChainMethods(String namespace) {
  switch (namespace) {
    case 'eip155':
      return EIP155.methods.values.toList();
    case 'solana':
      return Solana.methods.values.toList();
    case 'polkadot':
      return Polkadot.methods.values.toList();
    default:
      return [];
  }
}

List<String> getChainEvents(String namespace) {
  switch (namespace) {
    case 'eip155':
      return EIP155.events.values.toList();
    case 'solana':
      return Solana.events.values.toList();
    case 'polkadot':
      return Polkadot.events.values.toList();
    default:
      return [];
  }
}

Future<SessionRequestParams?> getParams(
  String method,
  String address, {
  String? rpcUrl,
}) async {
  switch (method) {
    case 'personal_sign':
      final bytes = utf8.encode(testSignData);
      final encoded = bytesToHex(bytes, include0x: true);
      return SessionRequestParams(
        method: method,
        params: [encoded, address],
      );
    case 'eth_sign':
      return SessionRequestParams(
        method: method,
        params: [address, testSignData],
      );
    case 'eth_signTypedData':
      return SessionRequestParams(
        method: method,
        params: [address, typedData],
      );
    case 'eth_signTransaction':
      return SessionRequestParams(
        method: method,
        params: [
          Transaction(
            from: EthereumAddress.fromHex(address),
            to: EthereumAddress.fromHex(
              '0x59e2f66C0E96803206B6486cDb39029abAE834c0',
            ),
            value: EtherAmount.fromInt(EtherUnit.finney, 12), // == 0.012
          ).toJson(),
        ],
      );
    case 'eth_sendTransaction':
      return SessionRequestParams(
        method: method,
        params: [
          Transaction(
            from: EthereumAddress.fromHex(address),
            to: EthereumAddress.fromHex(
              '0x59e2f66C0E96803206B6486cDb39029abAE834c0',
            ),
            value: EtherAmount.fromInt(EtherUnit.finney, 12), // == 0.012
          ).toJson(),
        ],
      );
    default:
      return null;
  }
}
