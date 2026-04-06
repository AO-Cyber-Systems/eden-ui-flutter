import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdenLoginPage', () {
    testWidgets('renders title and subtitle text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(
          onLogin: (_, __) async {},
          title: 'Welcome',
          subtitle: 'Sign in below',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign in below'), findsOneWidget);
    });

    testWidgets('has email and password input fields', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(onLogin: (_, __) async {}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('onLogin called with email and password', (tester) async {
      String? capturedEmail;
      String? capturedPassword;

      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(
          onLogin: (email, password) async {
            capturedEmail = email;
            capturedPassword = password;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Enter email into first TextField
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'user@test.com');
      await tester.enterText(textFields.at(1), 'secret123');

      // Tap sign in button
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(capturedEmail, 'user@test.com');
      expect(capturedPassword, 'secret123');
    });

    testWidgets('shows error for empty fields', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(onLogin: (_, __) async {}),
      ));
      await tester.pumpAndSettle();

      // Tap sign in without entering anything
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your email and password.'),
        findsOneWidget,
      );
    });

    testWidgets('onSignUpTap fires when sign up tapped', (tester) async {
      var signUpTapped = false;
      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(
          onLogin: (_, __) async {},
          onSignUpTap: () => signUpTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign up'));
      expect(signUpTapped, true);
    });

    testWidgets('onForgotPasswordTap fires when tapped', (tester) async {
      var forgotTapped = false;
      await tester.pumpWidget(MaterialApp(
        home: EdenLoginPage(
          onLogin: (_, __) async {},
          onForgotPasswordTap: () => forgotTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forgot password?'));
      expect(forgotTapped, true);
    });
  });
}
