import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewExample(isAdd: true),
                ));
              },
              child: const Text('N1+N2'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const QRViewExample(isAdd: false),
                ));
              },
              child: const Text('2^N'),
            ),
          ),
        ],
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  final bool isAdd;

  const QRViewExample({Key? key, required this.isAdd}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String? number1;
  String? number2;
  String? number3;
  List<String>? resultList;
  bool scanner = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void dispose() {
    super.dispose();
    number2 = null;
    number1 = null;
    number3 = null;
    resultList?.clear();
    controller?.dispose();
    scanner = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (result != null && scanner)
                          if (widget.isAdd)
                            Text(
                              '${describeEnum(result!.format)}  \nData: N1:$number1 + N2:$number2 = $number3',
                              style: const TextStyle(fontSize: 13),
                            )
                          else
                            Text('${describeEnum(result!.format)}  \nData: 2^$number2=$number3', style: const TextStyle(fontSize: 13))
                        else
                          const Text('Scan a code', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 30,
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return Text('Flash: ${snapshot.data}');
                            },
                          )),
                    ),
                    Container(
                      height: 30,
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                          onPressed: () async {
                            await controller?.flipCamera();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getCameraInfo(),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return Text('Camera facing ${describeEnum(snapshot.data!)}');
                              } else {
                                return const Text('loading');
                              }
                            },
                          )),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 30,
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller?.pauseCamera();
                        },
                        child: const Text('pause', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    Container(
                      height: 30,
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () async {
                          await controller?.resumeCamera();
                        },
                        child: const Text('resume', style: TextStyle(fontSize: 20)),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 || MediaQuery.of(context).size.height < 400) ? 150.0 : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        if (result != null) {
          if (widget.isAdd) {
            if (result!.code!.length < 400) {
              resultList = result!.code!.split("\n");
              print('_QRViewExampleState._onQRViewCreated ${resultList!.length}');
              print('_QRViewExampleState._onQRViewCreated1 ${result!.code!.runtimeType}');
              if (resultList!.length == 2) {
                number1 = resultList![0];
                number2 = resultList![1];
                number3=sumOfTwoDigits(resultList![0], resultList![1]);
                scanner = true;
              } else {
                snackBar(r'The value returned by the scanner does not have numbers separated by the "\n" character');
              }
            }
            else {
              snackBar('There was no information from the scanner');
            }
          }
          else {
            if (result!.code!.contains(RegExp(r"^[0-9]+$"))) {
              if (int.parse(result!.code!) < 10000) {
                result = scanData;
                number2=result!.code!;
                number3=  calculatePowerOfTwo(int.parse(result!.code!));
                scanner = true;
              } else {
                snackBar('The number on the scanner is greater than 10,000');
              }
            } else {
              snackBar('There was no information from the scanner');
            }
          }
        }
        else {
          snackBar("There was no information from the scanner");
        }
      });
    });
  }


  snackBar(String content) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 100),
      backgroundColor: Colors.red,
      content: Text(content),
    ));
  }
}
String calculatePowerOfTwo(int exponent) {
  if (exponent < 0) {
    throw ArgumentError('Exponent must be non-negative.');
  }

  String result = '1';
  for (int i = 0; i < exponent; i++) {
    result = multiplyByTwo(result);
  }
  return result;
}

String multiplyByTwo(String binaryNumber) {
  String result = '';
  int carry = 0;
  for (int i = binaryNumber.length - 1; i >= 0; i--) {
    int digit = int.parse(binaryNumber[i]);
    int product = (digit * 2) + carry;
    int newDigit = product % 10;
    carry = product ~/ 10;
    result = newDigit.toString() + result;
  }
  if (carry > 0) {
    result = carry.toString() + result;
  }
  return result;
}


String sumOfTwoDigits(String num1, String num2) {
  List<int> sum = [];
  int maxLength = num1.length > num2.length ? num1.length : num2.length;
  int carry = 0;

  for (int i = 0; i < maxLength; i++) {
    int digit1 = i < num1.length ? int.parse(num1[num1.length - 1 - i]) : 0;
    int digit2 = i < num2.length ? int.parse(num2[num2.length - 1 - i]) : 0;

    int currentSum = digit1 + digit2 + carry;
    int digit = currentSum % 10;
    carry = currentSum ~/ 10;

    sum.add(digit);
  }

  if (carry > 0) {
    sum.add(carry);
  }

  sum = sum.reversed.toList();
  return sum.join();
}
