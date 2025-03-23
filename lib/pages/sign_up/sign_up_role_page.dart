import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';

class SignUpRolePage extends StatelessWidget {
  const SignUpRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 125),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/images/logo.png"),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: CustomButton(
                            onPressed: () {
                              Navigator.pushNamed(context, "/driverSignUp");
                            },
                            bgColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            text: "Motorista",
                          ),
                        ),
                        const SizedBox(height: 40),
                        FractionallySizedBox(
                          widthFactor: 0.7,
                          child: CustomButton(
                            onPressed: () {},
                            bgColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                            text: "Passageiro",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
              child: FractionallySizedBox(
                widthFactor: 0.7,
                child: CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  bgColor: Theme.of(context).colorScheme.surfaceBright,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  text: "Voltar",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
