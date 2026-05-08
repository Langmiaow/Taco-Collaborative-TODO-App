import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taco/l10n/app_localizations.dart';
import 'package:taco/services/share_service.dart';


class AddPinPage extends StatefulWidget {
  const AddPinPage({super.key});

  @override
  State<AddPinPage> createState() => _AddPinPage();
}

class _AddPinPage extends State<AddPinPage> {
  String pin = "";
  bool loading = false;
  bool error = false;
  bool success = false;


  void addDigit(String d) {
    if (loading) return;
    if (pin.length >= 4) return;
    HapticFeedback.mediumImpact();
    setState(() {
      if (error) error = false;
      pin += d;
    });
  }

  void backspace() {
    if (loading) return;
    if (pin.isEmpty) return;
    setState(() {
      if (error) error = false;
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> confirm() async {
    if (pin.length != 4 || loading) return;

    setState(() => loading = true);
    try {
      final data = await ShareService.getSharedTodo(pin);

      if (!mounted) return;

      setState(() {
        success = true;
      });

      HapticFeedback.mediumImpact();
      await Future.delayed(Duration(milliseconds: 500));

      Navigator.pop(context, {
        "content": data["content"] ?? "",
        "remark": data["remark"] ?? "",
        "ddl": data["ddl"],
      });
    } catch (_) {
      HapticFeedback.mediumImpact();
      await Future.delayed(Duration(milliseconds: 80));
      HapticFeedback.mediumImpact();

      setState(() {
        pin = "";
        error = true;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget pinBox(int i) {
    String ch = i < pin.length ? pin[i] : "";
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: error
            ? Border.all(color: Color.fromARGB(255, 40, 110, 240), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Center(
        child: Text(
          ch,
          style: TextStyle(
            color: Color.fromARGB(255, 40, 110, 240),
            fontSize: 48,
          ),
        ),
      ),
    );
  }

  Widget keyBtn({String? text, IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: SizedBox(
            height: 72,
            child: Center(
              child: text != null
                  ? Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  color: loading ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              )
                  : Icon(
                icon,
                size: 26,
                color: loading ? Colors.grey : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    bool canConfirm = pin.length == 4 && !loading && !success;

    String btnText;
    if (success) {
      btnText = t.addSuccess;
    } else if (loading) {
      btnText = t.loading;
    } else if (error) {
      btnText = t.retryInput;
    } else {
      btnText = t.confirm;
    }



    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 237, 237),
      body: Column(
        children: [
          const SizedBox(height: 45),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 80,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Text(t.addByCodeTitle, style: TextStyle(fontSize: 32)),
                  const Spacer(),
                  Material(
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t.addByCodeHint,
              style: const TextStyle(fontSize: 22),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 60),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pinBox(0),
              const SizedBox(width: 20),
              pinBox(1),
              const SizedBox(width: 20),
              pinBox(2),
              const SizedBox(width: 20),
              pinBox(3),
            ],
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: canConfirm
                  ? const Color.fromARGB(255, 40, 110, 240)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: canConfirm ? confirm : null,
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: Text(
                      btnText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canConfirm ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                Row(children: [
                  keyBtn(text: "1", onTap: () => addDigit("1")),
                  keyBtn(text: "2", onTap: () => addDigit("2")),
                  keyBtn(text: "3", onTap: () => addDigit("3")),
                ]),
                Row(children: [
                  keyBtn(text: "4", onTap: () => addDigit("4")),
                  keyBtn(text: "5", onTap: () => addDigit("5")),
                  keyBtn(text: "6", onTap: () => addDigit("6")),
                ]),
                Row(children: [
                  keyBtn(text: "7", onTap: () => addDigit("7")),
                  keyBtn(text: "8", onTap: () => addDigit("8")),
                  keyBtn(text: "9", onTap: () => addDigit("9")),
                ]),
                Row(children: [
                  Expanded(child: SizedBox(height: 72)),
                  keyBtn(text: "0", onTap: () => addDigit("0")),
                  keyBtn(icon: Icons.backspace_outlined, onTap: backspace),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
