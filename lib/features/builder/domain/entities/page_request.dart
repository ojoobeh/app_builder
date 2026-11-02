import 'model_def.dart';

/// متدهای قابل انتخاب برای درخواست صفحه
const List<String> kRequestMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];

/// یک جفت key/value (برای پارامترها و هدرها).
/// مقدار می‌تواند `{value}` داشته باشد؛ هنگام اجرا با مقداری که صفحه‌ی قبلی فرستاده پر می‌شود.
class RequestParam {
  String key;
  String value;
  RequestParam({this.key = '', this.value = ''});
  RequestParam copy() => RequestParam(key: key, value: value);
}

/// درخواست خودکار صفحه: به‌محض ورود به صفحه به سرور زده می‌شود.
/// مقدار ورودی همان چیزی است که صفحه‌ی قبلی با دکمه فرستاده ({{args}} در bindingها و {value} در درخواست).
///
///  • url: آدرس؛ اگر `{value}` داشته باشد با مقدار ورودی جایگزین می‌شود (مثلاً https://x.com/users/{value})
///  • method: یکی از [kRequestMethods]
///  • params: پارامترهای ارسالی (id=..., name=...)
///  • paramsIn: محل ارسال پارامترها: 'auto' | 'query' | 'body' (به [paramsInBody] نگاه کن)
///  • headers: هدرها (مثلاً Authorization)
///  • responseType: نوع پاسخ (مثلاً User یا List<User>)؛ null = بدون نوع (فقط data خام)
///  • dataPath: مسیر داده داخل پاسخ (مثل data.items)؛ خالی = خود پاسخ.
///    هم برای «لیست داده‌ای» و هم برای ساختن responseType استفاده می‌شود.
class PageRequest {
  bool enabled;
  String url;
  String method;
  List<RequestParam> params;
  String paramsIn;
  List<RequestParam> headers;
  FieldType? responseType;
  String dataPath;

  PageRequest({
    this.enabled = false,
    this.url = '',
    this.method = 'GET',
    List<RequestParam>? params,
    this.paramsIn = 'auto',
    List<RequestParam>? headers,
    this.responseType,
    this.dataPath = '',
  })  : params = params ?? [],
        headers = headers ?? [];

  /// آیا پارامترها در بدنه‌ی JSON فرستاده می‌شوند؟
  /// auto: POST / PUT / PATCH → بدنه، GET / DELETE → کوئری. GET هرگز بدنه ندارد.
  bool get paramsInBody {
    if (method == 'GET') return false;
    if (paramsIn == 'body') return true;
    if (paramsIn == 'query') return false;
    return method != 'DELETE';
  }

  /// آیا درخواست به مقدار ارسالی صفحه‌ی قبلی ({value}) نیاز دارد؟
  bool get usesValue =>
      url.contains('{value}') ||
      params.any((pair) => pair.value.contains('{value}')) ||
      headers.any((pair) => pair.value.contains('{value}'));
}
