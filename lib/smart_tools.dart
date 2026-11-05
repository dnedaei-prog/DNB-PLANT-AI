import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'ambient_light_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF167B62);

class PlantIdentification {
  const PlantIdentification({required this.name, required this.photoPath});
  final String name;
  final String photoPath;
}
class SmartToolsPage extends StatefulWidget {
  const SmartToolsPage({super.key});
  @override State<SmartToolsPage> createState() => _SmartToolsPageState();
}
class _SmartToolsPageState extends State<SmartToolsPage> {
  final keyController = TextEditingController();
  String apiKey = '', status = 'برای شروع، شرایط محیط را دریافت کن.',
      location = 'هنوز دریافت نشده', weather = 'هنوز دریافت نشده',
      light = 'در حال بررسی حسگر نور...', plantResult = '', soilAdvice = '';
  String? plantPhoto, soilPhoto;
  bool busyLocation = false, busyPlant = false, hasLightSensor = false;
  List<Map<String, dynamic>> candidates = [];
  double? lux;
  StreamSubscription<double>? lightSubscription;
  @override void initState() { super.initState(); loadKey(); initLight(); }
  Future<void> loadKey() async {
    final p = await SharedPreferences.getInstance();
    apiKey = p.getString('plantnet_api_key') ?? '';
    keyController.text = apiKey;
    if (mounted) setState(() {});
  }
  Future<void> saveKey() async {
    apiKey = keyController.text.trim();
    final p = await SharedPreferences.getInstance();
    await p.setString('plantnet_api_key', apiKey);
    if (mounted) setState(() => status = apiKey.isEmpty ? 'کلید پاک شد.' : 'کلید روی همین گوشی ذخیره شد.');
  }
  Future<void> initLight() async {
    try {
      hasLightSensor = await AmbientLightService.hasSensor();
      if (!hasLightSensor) { if (mounted) setState(() => light = 'این گوشی حسگر نور محیط ندارد.'); return; }
      lightSubscription = AmbientLightService.luxStream().listen((v) {
        if (!mounted) return;
        final value = v.toDouble();
        setState(() { lux = value; light = '${value.toStringAsFixed(0)} لوکس — ${lightLabel(value)}'; });
      }, onError: (_) { if (mounted) setState(() => light = 'خواندن حسگر نور ممکن نشد.'); });
    } catch (_) { if (mounted) setState(() => light = 'حسگر نور در دسترس نیست.'); }
  }
  String lightLabel(double v) {
    if (v < 50) return 'بسیار کم';
    if (v < 500) return 'کم تا متوسط';
    if (v < 2000) return 'روشن';
    if (v < 10000) return 'بسیار روشن';
    return 'نور مستقیم یا بسیار شدید';
  }
  Future<void> getEnvironment() async {
    setState(() { busyLocation = true; status = 'در حال دریافت موقعیت و آب‌وهوا...'; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('سرویس مکان‌یابی گوشی خاموش است.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('دسترسی مکان داده نشد؛ از تنظیمات گوشی اجازه بده.');
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)));
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': pos.latitude.toString(), 'longitude': pos.longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
        'timezone': 'auto'
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('دریافت آب‌وهوا ناموفق بود: ${response.statusCode}');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final cur = data['current'] as Map<String, dynamic>;
      final units = data['current_units'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        location = 'عرض ${pos.latitude.toStringAsFixed(4)}، طول ${pos.longitude.toStringAsFixed(4)}';
        weather = 'دما: ${cur['temperature_2m']} ${units['temperature_2m']}\n'
          'دمای محسوس: ${cur['apparent_temperature']} ${units['apparent_temperature']}\n'
          'رطوبت: ${cur['relative_humidity_2m']} ${units['relative_humidity_2m']}\n'
          'باد: ${cur['wind_speed_10m']} ${units['wind_speed_10m']}\n'
          'بارش: ${cur['precipitation']} ${units['precipitation']}';
        status = 'موقعیت و آب‌وهوای فعلی دریافت شد.';
      });
    } catch (e) { if (mounted) setState(() => status = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busyLocation = false); }
  }
  Future<void> pickPlant(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, imageQuality: 88, maxWidth: 1800);
    if (f == null || !mounted) return;
    setState(() { plantPhoto = f.path; plantResult = ''; candidates = []; });
    await identifyPlant(f.path);
  }
  Future<void> identifyPlant(String path) async {
    if (apiKey.isEmpty) { setState(() => plantResult = 'ابتدا کلید API رایگان Pl@ntNet را در پایین صفحه وارد و ذخیره کن.'); return; }
    setState(() { busyPlant = true; plantResult = 'عکس در حال شناسایی است...'; candidates = []; });
    try {
      final req = http.MultipartRequest('POST', Uri.https('my-api.plantnet.org',
        '/v2/identify/all', {'api-key': apiKey, 'nb-results': '5'}));
      req.files.add(await http.MultipartFile.fromPath('images', path));
      req.fields['organs'] = 'auto';
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final msg = body is Map ? (body['message'] ?? body['error'] ?? response.body) : response.body;
        throw Exception('خطای سرویس (${response.statusCode}): $msg');
      }
      final results = body['results'] as List? ?? [];
      if (results.isEmpty) { if (mounted) setState(() => plantResult = 'نتیجه‌ای پیدا نشد؛ عکس واضح‌تری از برگ یا گل بگیر.'); return; }
      final parsed = <Map<String, dynamic>>[];
      for (final item in results.take(5)) {
        final species = item['species'] ?? {};
        parsed.add({
          'scientific': species['scientificNameWithoutAuthor'] ?? species['scientificName'] ?? 'نام علمی نامشخص',
          'common': (species['commonNames'] as List? ?? []).take(3).join('، '),
          'score': ((item['score'] ?? 0) * 100).toDouble(),
        });
      }
      if (mounted) setState(() {
        candidates = parsed;
        plantResult = parsed.isEmpty ? 'نتیجه‌ای پیدا نشد؛ عکس واضح‌تری بگیر.' : '۵ نتیجه احتمالی پیدا شد. برای استفاده در شناسنامه، یکی را انتخاب کن.';
      });
    } catch (e) { if (mounted) setState(() { plantResult = e.toString().replaceFirst('Exception: ', ''); candidates = []; }); }
    finally { if (mounted) setState(() => busyPlant = false); }
  }
  Future<void> pickSoil(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (f == null || !mounted) return;
    setState(() {
      soilPhoto = f.path;
      soilAdvice = 'عکس خاک ثبت شد. برای ارزیابی بهتر، عکس را در نور طبیعی و از سطح خاک بدون فیلتر بگیر. از روی عکس به‌تنهایی نمی‌توان pH، شوری، مواد غذایی یا سلامت ریشه را قطعی تشخیص داد. بافت ظاهری، فشردگی، پوسته‌بستن و مواد قابل مشاهده را بررسی کن.';
    });
  }
  Widget section(String title, IconData icon, Widget child) => Card(elevation: 0,
    margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: _green), const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 12), child])));
  Widget photoButtons(Future<void> Function(ImageSource) pick) => Wrap(spacing: 8, runSpacing: 8, children: [
    OutlinedButton.icon(onPressed: () => pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('عکس با دوربین')),
    OutlinedButton.icon(onPressed: () => pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('انتخاب از گالری'))]);
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('ابزارهای هوشمند گیاه')),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      section('مکان‌یابی و آب‌وهوای زنده', Icons.location_on, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(location), const SizedBox(height: 8), Text(weather), const SizedBox(height: 10),
        FilledButton.icon(onPressed: busyLocation ? null : getEnvironment, icon: const Icon(Icons.my_location),
          label: Text(busyLocation ? 'در حال دریافت...' : 'دریافت موقعیت و آب‌وهوا')),
        const Text('موقعیت فقط با اجازه شما دریافت می‌شود؛ مکان‌یابی پس‌زمینه فعال نیست.', style: TextStyle(fontSize: 11, color: Colors.black54))])),
      section('اندازه‌گیری نور محیط', Icons.wb_sunny, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(light, style: const TextStyle(fontSize: 16)),
        if (lux != null) const Text('مقدار لوکس روشنایی محل قرارگیری گوشی را نشان می‌دهد؛ گوشی را نزدیک برگ و بدون پوشاندن حسگر نگه دار.'),
        if (!hasLightSensor) const Text('اگر گوشی حسگر نور نداشته باشد، سنجش خودکار ممکن نیست.') ])),
      section('تشخیص گیاه از عکس', Icons.local_florist, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('از گل یا برگ عکس واضح بگیر؛ نتیجه شامل گونه‌های احتمالی و درصد تطابق است.'),
        const SizedBox(height: 10), photoButtons(pickPlant),
        if (plantPhoto != null) Padding(padding: const EdgeInsets.only(top: 10),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(plantPhoto!), height: 170, fit: BoxFit.cover))),
        if (busyPlant) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        if (plantResult.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(plantResult)),
        for (var i = 0; i < candidates.length; i++) Card(
          child: ListTile(
            title: Text(candidates[i]['common'].toString().isEmpty ? candidates[i]['scientific'].toString() : candidates[i]['common'].toString()),
            subtitle: Text(candidates[i]['scientific'].toString() + ' • تطابق ' + (candidates[i]['score'] as double).toStringAsFixed(1) + '٪'),
            trailing: const Icon(Icons.check_circle_outline),
            onTap: () => Navigator.pop(context, PlantIdentification(name: candidates[i]['common'].toString().isEmpty ? candidates[i]['scientific'].toString() : candidates[i]['common'].toString(), photoPath: plantPhoto ?? '')),
          ),
        ),
        const Divider(height: 24), const Text('کلید API رایگان Pl@ntNet', style: TextStyle(fontWeight: FontWeight.w600)),
        TextField(controller: keyController, obscureText: true, decoration: const InputDecoration(hintText: 'کلید شخصی API', border: OutlineInputBorder())),
        Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: saveKey, child: const Text('ذخیره کلید روی گوشی'))),
        const Text('کلید را از my.plantnet.org بخش API key دریافت کن. در این نسخه کلید روی گوشی ذخیره می‌شود؛ برای انتشار عمومی باید به سرور امن منتقل شود.',
          style: TextStyle(fontSize: 11, color: Colors.black54))])),
      section('عکس و بررسی خاک', Icons.grass, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('از سطح خاک عکس بگیر؛ خاک را قبل از عکس‌برداری دستکاری نکن.'),
        const SizedBox(height: 10), photoButtons(pickSoil),
        if (soilPhoto != null) Padding(padding: const EdgeInsets.only(top: 10),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(soilPhoto!), height: 170, fit: BoxFit.cover))),
        if (soilAdvice.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(soilAdvice)),
        const Text('تحلیل خودکار ترکیبات و pH خاک هنوز به موتور بینایی متصل نشده است؛ برای pH و شوری تست خاک لازم است.',
          style: TextStyle(fontSize: 11, color: Colors.black54))])),
      Text(status, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 12)
    ]));
  @override void dispose() { lightSubscription?.cancel(); keyController.dispose(); super.dispose(); }
}
