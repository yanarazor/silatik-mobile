import 'package:dio/dio.dart';

import 'app.dart';
import 'core/utils/api_error_handler.dart';

void main() {
  DioException.readableStringBuilder = ApiErrorHandler.getMessage;
  bootstrap();
}
