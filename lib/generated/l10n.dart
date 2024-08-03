// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Invoice or Phone Number`
  String get invoiceOrPhoneNumber {
    return Intl.message(
      'Invoice or Phone Number',
      name: 'invoiceOrPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Call`
  String get call {
    return Intl.message(
      'Call',
      name: 'call',
      desc: '',
      args: [],
    );
  }

  /// `Ar`
  String get changeLanguage {
    return Intl.message(
      'Ar',
      name: 'changeLanguage',
      desc: '',
      args: [],
    );
  }

  /// `En`
  String get currentLanguage {
    return Intl.message(
      'En',
      name: 'currentLanguage',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get order {
    return Intl.message(
      'Order',
      name: 'order',
      desc: '',
      args: [],
    );
  }

  /// `Device`
  String get device {
    return Intl.message(
      'Device',
      name: 'device',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get phone {
    return Intl.message(
      'Phone',
      name: 'phone',
      desc: '',
      args: [],
    );
  }

  /// `Add New Device`
  String get add_new_device {
    return Intl.message(
      'Add New Device',
      name: 'add_new_device',
      desc: '',
      args: [],
    );
  }

  /// `New Order`
  String get new_order {
    return Intl.message(
      'New Order',
      name: 'new_order',
      desc: '',
      args: [],
    );
  }

  /// `Wednesday\n2024/12/12`
  String get date {
    return Intl.message(
      'Wednesday\n2024/12/12',
      name: 'date',
      desc: '',
      args: [],
    );
  }

  /// `Invoice Number`
  String get invoice_number {
    return Intl.message(
      'Invoice Number',
      name: 'invoice_number',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phone_number {
    return Intl.message(
      'Phone Number',
      name: 'phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Device Number`
  String get device_number {
    return Intl.message(
      'Device Number',
      name: 'device_number',
      desc: '',
      args: [],
    );
  }

  /// `Now Preparing`
  String get preparing_device {
    return Intl.message(
      'Now Preparing',
      name: 'preparing_device',
      desc: '',
      args: [],
    );
  }

  /// `Device Number`
  String get device2 {
    return Intl.message(
      'Device Number',
      name: 'device2',
      desc: '',
      args: [],
    );
  }

  /// `Ready Check`
  String get ready_check {
    return Intl.message(
      'Ready Check',
      name: 'ready_check',
      desc: '',
      args: [],
    );
  }

  /// `Ready`
  String get ready {
    return Intl.message(
      'Ready',
      name: 'ready',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
