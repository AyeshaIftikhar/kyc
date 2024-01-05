import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swiperrep/screens/webview_screen.dart';

class CalendlyServices {
  static String clientid = 'muoAKG32E_23xO3xmCYP_qaQELKbD5PPqu2sTPRCTbQ';
  static String clientSecret = 'Wf2hZlEfT7NB4qQEVtX7fkCbn331554_lyvz78hrdVs';
  static String webhookKey = '82HirWuvOeL2Nc4-7fGz_oQZjlxFDrzv7wvKYeFbvH4';
  static String redirect = 'https://www.swiperep.com/home';
  static String codeVerifier =
      'b3633a6919329ba5dc439f0ad38087007e1f808ba4062fc863139878';
  static String codeChallenge = 'eGgDFnHL8PTZWEcTnV3rli_mDHLwT0BzKHMY6wOvzm8';

  String token = '';

//com.site.app://auth/calendly

  static getAutorizationCode() async {
    try {
      // Uri uri = Uri.parse(
      //   'https://auth.calendly.com/oauth/authorize?client_id=$clientid&response_type=code&redirect_uri=$redirect&code_challenge_method=S256&code_challenge=CODE_CHALLENGE',
      // );
      // final response = await http.get(uri);
      // debugPrint('resonse: ${response.body}');
      Get.to(
        () => WebViewScreen(
          html:
              'https://auth.calendly.com/oauth/authorize?client_id=$clientid&response_type=code&redirect_uri=$redirect&code_challenge_method=S256&code_challenge=$codeChallenge',
        ),
      );
    } catch (e, stack) {
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stack');
    }
  }

  static String getCode(String url) {
    return url.split('?').last;
  }
}
