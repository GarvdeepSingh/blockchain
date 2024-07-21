import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_expense_manager_dapp/models/transaction_model.dart';
import 'package:meta/meta.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardInitialFechEvent>(dashboardInitialFechEvent);
    on<DashboardDepositEvent>(dashboardDepositEvent);
    on<DashboardWithdrawEvent>(dashboardWithdrawEvent);
  }

  List<TransactionModel> transactions = [];
  Web3Client? _web3Client;
  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  late EthPrivateKey _creds;
  int balance = 0;

  // Functions
  late DeployedContract _deployedContract;
  late ContractFunction _deposit;
  late ContractFunction _withdraw;
  late ContractFunction _getBalance;
  late ContractFunction _getAllTransactions;

  FutureOr<void> dashboardInitialFechEvent(
      DashboardInitialFechEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoadingState());
    try {
      String rpcUrl = "HTTP://192.168.181.159:7545";
      String socketUrl = "ws://192.168.181.159:7545";
      String privateKey =
          "0xa32cf075e9a8d56fb85d3860b6d4053ae38d86cff3e5a345296ef5bf87a6f2f4";

      _web3Client = Web3Client(
        rpcUrl,
        http.Client(),
        socketConnector: () {
          return IOWebSocketChannel.connect(socketUrl).cast<String>();
        },
      );

      // getABI
      String abiFile = await rootBundle
          .loadString('build/contracts/ExpenseManagerContract.json');
      var jsonDecoded = jsonDecode(abiFile);

      _abiCode = ContractAbi.fromJson(
          jsonEncode(jsonDecoded["abi"]), 'ExpenseManagerContract');

      _contractAddress =
          EthereumAddress.fromHex("0x1109e933BE7A3f76a57a5f657d60911C73D2d510");

      _creds = EthPrivateKey.fromHex(privateKey);

      // get deployed contract
      _deployedContract = DeployedContract(_abiCode, _contractAddress);
      _deposit = _deployedContract.function("deposit");
      _withdraw = _deployedContract.function("withdraw");
      _getBalance = _deployedContract.function("getBalance");

      _getAllTransactions = _deployedContract.function("getAllTransactions");

      final transactionsData = await _web3Client!.call(
          contract: _deployedContract,
          function: _getAllTransactions,
          params: []);
      final balanceData = await _web3Client!
          .call(contract: _deployedContract, function: _getBalance, params: [
        EthereumAddress.fromHex("0x51c2E24De12150d614815a224D9e0d8eF78668D9")
      ]);

      List<TransactionModel> trans = [];
      for (int i = 0; i < transactionsData[0].length; i++) {
        TransactionModel transactionModel = TransactionModel(
            transactionsData[0][i].toString(),
            transactionsData[1][i].toInt(),
            transactionsData[2][i],
            DateTime.fromMicrosecondsSinceEpoch(
                transactionsData[3][i].toInt()));
        trans.add(transactionModel);
      }
      transactions = trans;

      int bal = balanceData[0].toInt();
      balance = bal;

      emit(DashboardSuccessState(transactions: transactions, balance: balance));
    } catch (e) {
      log(e.toString());
      emit(DashboardErrorState());
    }
  }

  FutureOr<void> dashboardDepositEvent(
      DashboardDepositEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
          from: EthereumAddress.fromHex(
              "0x51c2E24De12150d614815a224D9e0d8eF78668D9"),
          contract: _deployedContract,
          function: _deposit,
          parameters: [
            BigInt.from(event.transactionModel.amount),
            event.transactionModel.reason
          ],
          value: EtherAmount.inWei(BigInt.from(event.transactionModel.amount)));

      final result = await _web3Client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      log(result.toString());
      add(DashboardInitialFechEvent());
    } catch (e) {
      log(e.toString());
    }
  }

  FutureOr<void> dashboardWithdrawEvent(
      DashboardWithdrawEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(
            "0x51c2E24De12150d614815a224D9e0d8eF78668D9"),
        contract: _deployedContract,
        function: _withdraw,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason
        ],
      );

      final result = await _web3Client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      log(result.toString());
      add(DashboardInitialFechEvent());
    } catch (e) {
      log(e.toString());
    }
  }
}
