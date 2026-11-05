import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'reminder_service.dart';
import 'smart_tools.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); try { await ReminderService.initialize(); } catch (_) {} runApp(const DnbApp()); }
const green=Color(0xFF167B62),pale=Color(0xFFE8F4EE);
class Plant{
 Plant({required this.id,required this.name,required this.place,required this.condition,required this.notes,required this.photo,required this.created,required this.active,List<Map<String,dynamic>>? history}):history=history??[];
 final String id;String name,place,condition,notes,photo;final String created;bool active;final List<Map<String,dynamic>> history;
 Map<String,dynamic> json()=>{'id':id,'name':name,'place':place,'condition':condition,'notes':notes,'photo':photo,'created':created,'active':active,'history':history};
 factory Plant.from(Map j)=>Plant(id:j['id']??'',name:j['name']??'',place:j['place']??'',condition:j['condition']??'',notes:j['notes']??'',photo:j['photo']??'',created:j['created']??'',active:j['active']??false,history:List<Map<String,dynamic>>.from((j['history']??[]).map((e)=>Map<String,dynamic>.from(e))));
}
class DnbApp extends StatefulWidget{const DnbApp({super.key});@override State<DnbApp> createState()=>DnbState();}
class DnbState extends State<DnbApp>{
 List<Plant> plants=[];List<Map<String,dynamic>> careReminders=[];bool ready=false,reminders=true;String lang='فارسی',quiet='۲۲:۰۰ تا ۰۸:۰۰';
 @override void initState(){super.initState();load();}
 Future<void> load()async{final s=await SharedPreferences.getInstance();try{plants=(jsonDecode(s.getString('plants')??'[]') as List).map((e)=>Plant.from(e)).toList();}catch(_){}lang=s.getString('lang')??lang;reminders=s.getBool('reminders')??true;quiet=s.getString('quiet')??quiet;try{careReminders=List<Map<String,dynamic>>.from((jsonDecode(s.getString('care_reminders')??'[]') as List).map((e)=>Map<String,dynamic>.from(e)));}catch(_){}if(reminders){for(final item in careReminders){try{await ReminderService.schedule(id:item['id'],plant:item['plant'],title:item['title'],when:DateTime.parse(item['when']),repeat:item['repeat'],priority:item['priority'],quietHours:quiet);}catch(_){}}}if(mounted)setState(()=>ready=true);}
 Future<void> save()async{final s=await SharedPreferences.getInstance();await s.setString('plants',jsonEncode(plants.map((e)=>e.json()).toList()));await s.setString('lang',lang);await s.setBool('reminders',reminders);await s.setString('quiet',quiet);await s.setString('care_reminders',jsonEncode(careReminders));if(mounted)setState((){});}
 Future<void> add(Plant p)async{setState(()=>plants.insert(0,p));await save();}
 String newPlantId()=> 'DNB-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff).toRadixString(16)}';
 Future<String> persistPhoto(String sourcePath)async{
  final root=await getApplicationDocumentsDirectory();
  final folder=Directory('${root.path}/plant_photos');
  await folder.create(recursive:true);
  final extension=sourcePath.contains('.')?sourcePath.substring(sourcePath.lastIndexOf('.')):'.jpg';
  final target=File('${folder.path}/plant_${DateTime.now().microsecondsSinceEpoch}${extension}');
  return (await File(sourcePath).copy(target.path)).path;
 }
 Future<void> removePlant(Plant plant)async{
  plants.removeWhere((p)=>p.id==plant.id);
  await save();
  if(plant.photo.isNotEmpty){
   try{final file=File(plant.photo);if(await file.exists())await file.delete();}catch(_){}
  }
 }

 int newReminderId(){
 final random=Random.secure();
 for(var i=0;i<100;i++){
  final candidate=random.nextInt(900000000)+1;
  if(!careReminders.any((x)=>x['id']==candidate))return candidate;
 }
 throw StateError('شناسه یکتای یادآوری ساخته نشد');
}
Future<void> addCareReminder(Map<String,dynamic> item)async{
 if(reminders){
  await ReminderService.schedule(id:item['id'],plant:item['plant'],title:item['title'],when:DateTime.parse(item['when']),repeat:item['repeat'],priority:item['priority'],quietHours:quiet);
 }
 careReminders.add(item);
 await save();
}
 Future<void> removeCareReminder(Map<String,dynamic> item)async{await ReminderService.cancel(item['id']);await ReminderService.cancel(item['id']+1000000000);careReminders.removeWhere((x)=>x['id']==item['id']);await save();}
 Future<void> setReminderEnabled(bool enabled)async{reminders=enabled;if(enabled){for(final item in careReminders){await ReminderService.schedule(id:item['id'],plant:item['plant'],title:item['title'],when:DateTime.parse(item['when']),repeat:item['repeat'],priority:item['priority'],quietHours:quiet);}}else{for(final item in careReminders){await ReminderService.cancel(item['id']);await ReminderService.cancel(item['id']+1000000000);}}await save();}
 Future<void> updateQuietHours(String value)async{quiet=value;if(reminders){for(final item in careReminders){await ReminderService.schedule(id:item['id'],plant:item['plant'],title:item['title'],when:DateTime.parse(item['when']),repeat:item['repeat'],priority:item['priority'],quietHours:quiet);}}await save();}
 Future<void> snoozeCareReminder(Map<String,dynamic> item)async{await ReminderService.snooze(id:item['id'],plant:item['plant'],title:item['title'],priority:item['priority'],quietHours:quiet);}
 void refresh(){setState((){});save();}
 @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'DNB Plant AI',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:green),scaffoldBackgroundColor:const Color(0xFFF5F8F5)),home:Directionality(textDirection:TextDirection.rtl,child:ready?Home(app:this):const Scaffold(body:Center(child:CircularProgressIndicator()))));
}
void go(BuildContext c,Widget w)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:w)));
void toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));
class Home extends StatelessWidget{const Home({super.key,required this.app});final DnbState app;
 @override Widget build(BuildContext c){final active=app.plants.where((p)=>p.active).length;final saved=app.plants.length-active;return Scaffold(appBar:AppBar(title:const Text('DNB Plant AI'),centerTitle:true,actions:[IconButton(onPressed:()=>go(c,Settings(app:app)),icon:const Icon(Icons.settings))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xFF125C50),Color(0xFF279B78)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.energy_savings_leaf,color:Colors.white,size:38),SizedBox(height:12),Text('دانا زبان گیاه شما',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),SizedBox(height:6),Text('همراه ثبت و مراقبت آگاهانه از گیاهان',style:TextStyle(color:Colors.white))])),
 const SizedBox(height:12),Row(children:[stat('گیاهان من',active),const SizedBox(width:8),stat('اطلاعات ذخیره',saved)]),const SizedBox(height:14),
 tile(c,'ثبت جدید','ثبت عکس و وضعیت اولیه',Icons.add_a_photo,()=>go(c,Register(app:app))),
 tile(c,'هوش گیاه و محیط','تشخیص عکس، مکان، آب‌وهوا، نور و خاک',Icons.auto_awesome,()=>go(c,const SmartToolsPage())),
 tile(c,'گیاهان من','شناسنامه مستقل و تاریخچه هر گیاه',Icons.local_florist,()=>go(c,PlantList(app:app,active:true))),
 tile(c,'اطلاعات ذخیره','موارد ذخیره‌شده برای بررسی بعدی',Icons.bookmark,()=>go(c,PlantList(app:app,active:false))),
 tile(c,'یادآوری و آلارم','زمان‌بندی مراقبت و هشدارهای گیاهان',Icons.notifications_active,()=>go(c,ReminderCenter(app:app))),
 tile(c,'تکثیر','راهنمای قلمه، بذر و تقسیم',Icons.content_cut,()=>go(c,Propagation(app:app))),
 tile(c,'گفت‌وگو با دانا','یادداشت و پرسش درباره مراقبت',Icons.chat,()=>go(c,Chat(app:app))),
 tile(c,'نمودار وضعیت','روند ثبت‌های سه ماه اخیر',Icons.show_chart,()=>go(c,Trend(app:app))),
 tile(c,'تنظیمات','زبان، یادآوری و ساعات سکوت',Icons.settings,()=>go(c,Settings(app:app))),
 const SizedBox(height:12),const Text('نسخه آزمایشی محلی • اطلاعات روی همین دستگاه ذخیره می‌شود',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54,fontSize:11))]));}
 Widget stat(String s,int n)=>Expanded(child:Card(elevation:0,child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Expanded(child:Text(s)),Text(n.toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]))));
 Widget tile(BuildContext c,String t,String sub,IconData i,VoidCallback f)=>Card(elevation:0,margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:CircleAvatar(backgroundColor:pale,child:Icon(i,color:green)),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_left),onTap:f));
}
class Register extends StatefulWidget{const Register({super.key,required this.app,this.initialActive=true,this.returnToList=false});final DnbState app;final bool initialActive,returnToList;@override State<Register> createState()=>RegisterState();}
class RegisterState extends State<Register>{
 final name=TextEditingController(),notes=TextEditingController();String place='بالکن',condition='متوسط',photo='';late bool active;bool busy=false;
 @override void initState(){super.initState();active=widget.initialActive;}
 Future<void> identifyForRegistration()async{
  final result=await Navigator.push<PlantIdentification>(context,MaterialPageRoute(builder:(_)=>const SmartToolsPage()));
  if(result!=null&&mounted){
   try{
    final savedPhoto=result.photoPath.isEmpty?'':await widget.app.persistPhoto(result.photoPath);
    if(mounted)setState((){name.text=result.name;photo=savedPhoto;});
   }catch(e){if(mounted)toast(context,'نام شناسایی شد اما ذخیره عکس ناموفق بود: $e');}
  }
 }
 Future<void> pick(ImageSource source)async{
  final x=await ImagePicker().pickImage(source:source,imageQuality:82,maxWidth:1600);
  if(x==null)return;
  try{final saved=await widget.app.persistPhoto(x.path);if(mounted)setState(()=>photo=saved);}
  catch(e){if(mounted)toast(context,'ذخیره عکس ناموفق بود: $e');}
 }
 Future<void> submit()async{if(name.text.trim().isEmpty){toast(context,'نام گیاه را وارد کن');return;}setState(()=>busy=true);final d=DateTime.now();final p=Plant(id:widget.app.newPlantId(),name:name.text.trim(),place:place,condition:condition,notes:notes.text.trim(),photo:photo,created:d.toIso8601String(),active:active,history:[{'date':d.toIso8601String(),'condition':condition,'notes':notes.text.trim()}]);await widget.app.add(p);if(!mounted)return;if(widget.returnToList){Navigator.pop(context);toast(context,'${p.name} به فهرست اضافه شد');return;}Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:Chat(app:widget.app,initial:'گیاه ${p.name} ثبت شد. هر زمان خواستی می‌توانی درباره آن سؤال کنی؛ گفت‌وگو به ثبت شناسنامه وابسته نیست.'))));}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('ثبت جدید')),body:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('شناسنامه اولیه گیاه',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:14),TextField(controller:name,decoration:const InputDecoration(labelText:'نام گیاه یا نام دلخواه',hintText:'مثلاً شمعدانی شماره ۱',border:OutlineInputBorder())),
 const SizedBox(height:8),OutlinedButton.icon(onPressed:identifyForRegistration,icon:const Icon(Icons.auto_awesome),label:const Text('شناسایی نام گیاه از عکس با دانا')),const SizedBox(height:12),DropdownButtonFormField<String>(value:place,decoration:const InputDecoration(labelText:'محل نگهداری',border:OutlineInputBorder()),items:['بالکن','داخل منزل','حیاط','گلخانه','سایه','آفتاب مستقیم'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>place=v??place)),
 const SizedBox(height:12),DropdownButtonFormField<String>(value:condition,decoration:const InputDecoration(labelText:'وضعیت اولیه',border:OutlineInputBorder()),items:['عالی','خوب','متوسط','ضعیف','نیازمند بررسی'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>condition=v??condition)),
 const SizedBox(height:12),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'توضیحات، آبیاری، خاک و نور',border:OutlineInputBorder())),
 const SizedBox(height:12),Wrap(spacing:8,children:[OutlinedButton.icon(onPressed:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt),label:const Text('دوربین')),OutlinedButton.icon(onPressed:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library),label:Text(photo.isEmpty?'گالری':'عکس انتخاب شد'))]),
 if(photo.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(photo),height:180,fit:BoxFit.cover))),
 SwitchListTile(value:active,onChanged:(v)=>setState(()=>active=v),title:const Text('افزودن به «گیاهان من»'),subtitle:const Text('خاموش باشد، فقط در اطلاعات ذخیره می‌ماند')),
 const SizedBox(height:14),FilledButton(onPressed:busy?null:submit,child:const Text('ذخیره شناسنامه'))]));
}
class PlantList extends StatelessWidget{const PlantList({super.key,required this.app,required this.active});final DnbState app;final bool active;
 Future<void> addPlant(BuildContext c)async{go(c,Register(app:app,initialActive:active,returnToList:true));}
 @override Widget build(BuildContext c){final items=app.plants.where((p)=>p.active==active).toList();return Scaffold(appBar:AppBar(title:Text(active?'گیاهان من':'اطلاعات ذخیره'),actions:[IconButton(tooltip:'افزودن مورد جدید',onPressed:()=>addPlant(c),icon:const Icon(Icons.add))]),floatingActionButton:FloatingActionButton.extended(onPressed:()=>addPlant(c),icon:const Icon(Icons.add),label:Text(active?'افزودن گیاه':'افزودن مورد ذخیره')),body:items.isEmpty?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(active?Icons.local_florist:Icons.bookmark_border,size:54,color:green),const SizedBox(height:12),Text(active?'هنوز گیاهی به فهرست اضافه نشده است':'هنوز اطلاعاتی ذخیره نشده است',style:const TextStyle(fontSize:16)),const SizedBox(height:12),FilledButton.icon(onPressed:()=>addPlant(c),icon:const Icon(Icons.add),label:Text(active?'افزودن اولین گیاه':'ذخیره مورد جدید'))])):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){final p=items[i];return Card(elevation:0,child:ListTile(leading:p.photo.isEmpty?const CircleAvatar(child:Icon(Icons.local_florist)):CircleAvatar(backgroundImage:FileImage(File(p.photo))),title:Text(p.name),subtitle:Text(p.place+' • '+p.condition),trailing:const Icon(Icons.chevron_left),onTap:()=>go(c,Profile(app:app,plant:p))));}));}
}
class Profile extends StatefulWidget{const Profile({super.key,required this.app,required this.plant});final DnbState app;final Plant plant;@override State<Profile> createState()=>ProfileState();}
class ProfileState extends State<Profile>{
 final note=TextEditingController();
 final editName=TextEditingController(),editPlace=TextEditingController(),editNotes=TextEditingController();
 String condition='خوب';
 @override void initState(){super.initState();editName.text=widget.plant.name;editPlace.text=widget.plant.place;editNotes.text=widget.plant.notes;}
 Future<void> editPlant()async{
  final p=widget.plant;
  final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(
   title:const Text('ویرایش شناسنامه'),
   content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    TextField(controller:editName,decoration:const InputDecoration(labelText:'نام گیاه')),
    TextField(controller:editPlace,decoration:const InputDecoration(labelText:'محل نگهداری')),
    TextField(controller:editNotes,maxLines:3,decoration:const InputDecoration(labelText:'یادداشت‌ها')),
   ])),
   actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('ذخیره تغییرات'))],
  ));
  if(ok==true&&editName.text.trim().isNotEmpty){
   p.name=editName.text.trim();p.place=editPlace.text.trim();p.notes=editNotes.text.trim();
   widget.app.refresh();
   if(mounted)setState((){});
   toast(context,'شناسنامه به‌روزرسانی شد');
  }
 }
 @override void dispose(){note.dispose();editName.dispose();editPlace.dispose();editNotes.dispose();super.dispose();}
 @override Widget build(BuildContext c){final p=widget.plant;return Scaffold(appBar:AppBar(title:Text(p.name),actions:[PopupMenuButton<String>(onSelected:(v)async{if(v=='edit'){await editPlant();}else if(v=='delete'){final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('حذف شناسنامه'),content:Text('اطلاعات و تاریخچه «${p.name}» حذف شود؟'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('انصراف')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('حذف'))]));if(ok==true){await widget.app.removePlant(p);if(c.mounted)Navigator.pop(c);}}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('ویرایش شناسنامه')),PopupMenuItem(value:'delete',child:Text('حذف شناسنامه'))])]),body:ListView(padding:const EdgeInsets.all(16),children:[
 if(p.photo.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.file(File(p.photo),height:210,fit:BoxFit.cover)),
 Text(p.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text('شناسه: '+p.id),Text('محل: '+p.place+' • وضعیت اولیه: '+p.condition),const Divider(height:28),
 const Text('ثبت وضعیت جدید',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 DropdownButtonFormField<String>(value:condition,items:['عالی','خوب','متوسط','ضعیف','نیازمند بررسی'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>condition=v??condition)),
 const SizedBox(height:8),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'شرح وضعیت، آبیاری، نور و تغییرات',border:OutlineInputBorder())),
 const SizedBox(height:8),FilledButton(onPressed:(){p.history.add({'date':DateTime.now().toIso8601String(),'condition':condition,'notes':note.text});widget.app.refresh();note.clear();toast(c,'وضعیت جدید ثبت شد');},child:const Text('ثبت وضعیت')),
 const Divider(height:28),Text('تاریخچه ('+p.history.length.toString()+' مورد)',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 for(final h in p.history.reversed)ListTile(leading:const Icon(Icons.history,color:green),title:Text(h['condition']??''),subtitle:Text((h['date']??'').toString().split('T').first+'  '+(h['notes']??''))),
 if(!p.active)FilledButton.tonal(onPressed:(){p.active=true;widget.app.refresh();Navigator.pop(c);},child:const Text('افزودن به گیاهان من')),
 OutlinedButton(onPressed:()=>go(c,Chat(app:widget.app,initial:'درباره گیاه '+p.name+' راهنمایی می‌خواهم.')),child:const Text('گفت‌وگو با دانا'))]));}
}
class Chat extends StatefulWidget{const Chat({super.key,required this.app,this.initial=''});final DnbState app;final String initial;@override State<Chat> createState()=>ChatState();}
class ChatState extends State<Chat>{final input=TextEditingController();final messages=<String>[];@override void initState(){super.initState();if(widget.initial.isNotEmpty)messages.add('دانا: '+widget.initial);}
 void send(){final s=input.text.trim();if(s.isEmpty)return;setState((){messages.add('شما: '+s);messages.add('دانا: پرسشت دریافت شد. در نسخه آزمایشی فعلی موتور پاسخ‌گویی هوشمند هنوز متصل نیست؛ اما برای شروع گفت‌وگو نیازی به ثبت گیاه یا ساخت شناسنامه نداری.');});input.clear();}
 @override void dispose(){input.dispose();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('گفت‌وگو با دانا')),body:Column(children:[Container(width:double.infinity,padding:const EdgeInsets.all(12),color:pale,child:const Text('گفت‌وگو مستقل است؛ بدون ثبت گیاه هم می‌توانی سؤال عمومی بپرسی. اگر موضوعت گیاه مشخصی است، نامش را بنویس یا از شناسنامه همان گیاه وارد شو.',style:TextStyle(fontSize:12))),Expanded(child:messages.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('سلام! هر پرسشی درباره گیاهان و نگهداری آن‌ها داری همین‌جا بنویس. برای شروع نیازی به ثبت یا انتخاب گیاه نیست.',textAlign:TextAlign.center))):ListView(padding:const EdgeInsets.all(12),children:[for(final m in messages)Card(elevation:0,child:Padding(padding:const EdgeInsets.all(12),child:Text(m)))])),Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:input,onSubmitted:(_)=>send(),minLines:1,maxLines:4,decoration:const InputDecoration(hintText:'پیامت را بنویس...',border:OutlineInputBorder()))),IconButton(onPressed:send,icon:const Icon(Icons.send,color:green))]))])); 
}
class ReminderCenter extends StatefulWidget{const ReminderCenter({super.key,required this.app});final DnbState app;@override State<ReminderCenter> createState()=>ReminderCenterState();}
class ReminderCenterState extends State<ReminderCenter>{
 final title=TextEditingController();DateTime date=DateTime.now().add(const Duration(days:1));TimeOfDay time=const TimeOfDay(hour:9,minute:0);String repeat='یک‌بار',plant='عمومی';int priority=0;bool busy=false;
 @override void initState(){super.initState();final names=widget.app.plants.where((p)=>p.active).map((p)=>p.name).toList();if(names.isNotEmpty)plant=names.first;}
 Future<void> chooseDate()async{final d=await showDatePicker(context:context,initialDate:date.isBefore(DateTime.now())?DateTime.now():date,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:730)));if(d!=null)setState(()=>date=d);}
 Future<void> chooseTime()async{final t=await showTimePicker(context:context,initialTime:time);if(t!=null)setState(()=>time=t);}
 Future<void> saveReminder()async{if(title.text.trim().isEmpty){toast(context,'عنوان یادآوری را بنویس');return;}var when=DateTime(date.year,date.month,date.day,time.hour,time.minute);if(repeat=='یک‌بار'&&!when.isAfter(DateTime.now())){toast(context,'زمان یادآوری باید در آینده باشد');return;}setState(()=>busy=true);final id=widget.app.newReminderId();final item=<String,dynamic>{'id':id,'plant':plant,'title':title.text.trim(),'when':when.toIso8601String(),'repeat':repeat,'priority':priority};try{await widget.app.addCareReminder(item);if(mounted){title.clear();toast(context,'یادآوری ذخیره و زمان‌بندی شد');}}catch(e){if(mounted)toast(context,'ذخیره شد، اما زمان‌بندی اعلان با خطا روبه‌رو شد: $e');}if(mounted)setState(()=>busy=false);}
 @override Widget build(BuildContext c){final names=widget.app.plants.where((p)=>p.active).map((p)=>p.name).toSet().toList();if(!names.contains(plant))plant=names.isEmpty?'عمومی':names.first;return Scaffold(appBar:AppBar(title:const Text('یادآوری و آلارم')),body:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('یادآوری مراقبت',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:10),
 TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان کار',hintText:'مثلاً بررسی رطوبت خاک یا کوددهی',border:OutlineInputBorder())),
 const SizedBox(height:10),DropdownButtonFormField<String>(value:plant,decoration:const InputDecoration(labelText:'مربوط به کدام گیاه؟',border:OutlineInputBorder()),items:['عمومی',...names].toSet().map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>plant=v??plant)),
 const Padding(padding:EdgeInsets.only(top:6),child:Text('هر یادآوری به گیاه انتخاب‌شده متصل می‌شود؛ برای هر گیاه می‌توان چند تاریخ و ساعت مستقل ثبت کرد.',style:TextStyle(fontSize:12,color:Colors.black54))),
 const SizedBox(height:10),Row(children:[Expanded(child:OutlinedButton.icon(onPressed:chooseDate,icon:const Icon(Icons.calendar_month),label:Text('${date.year}/${date.month}/${date.day}'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:chooseTime,icon:const Icon(Icons.access_time),label:Text(time.format(c))))]),
 const SizedBox(height:10),DropdownButtonFormField<String>(value:repeat,decoration:const InputDecoration(labelText:'تکرار',border:OutlineInputBorder()),items:['یک‌بار','روزانه','هفتگی'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>repeat=v??repeat)),
 const SizedBox(height:10),DropdownButtonFormField<int>(value:priority,decoration:const InputDecoration(labelText:'اولویت هشدار',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:0,child:Text('عادی')),DropdownMenuItem(value:1,child:Text('مهم')),DropdownMenuItem(value:2,child:Text('فوری'))],onChanged:(v)=>setState(()=>priority=v??0)),
 const SizedBox(height:8),Text('ساعات سکوت فعلی: ${widget.app.quiet}',style:const TextStyle(color:Colors.black54)),const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:saveReminder,icon:const Icon(Icons.notifications_active),label:const Text('ذخیره و تنظیم آلارم')),
 const Divider(height:30),const Text('یادآوری‌های ثبت‌شده',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
 if(widget.app.careReminders.isEmpty)const Padding(padding:EdgeInsets.all(18),child:Text('هنوز یادآوری ثبت نشده است')),
 for(final item in widget.app.careReminders.reversed)Card(elevation:0,child:ListTile(leading:Icon(item['priority']==2?Icons.warning_amber:item['priority']==1?Icons.notifications_active:Icons.notifications,color:item['priority']==2?Colors.red:green),title:Text(item['title']),subtitle:Text('${item['plant']} • ${item['repeat']} • ${DateTime.parse(item['when']).toLocal()}'),isThreeLine:true,trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='snooze'){await widget.app.snoozeCareReminder(item);if(c.mounted)toast(c,'یک ساعت به تعویق افتاد');}else{await widget.app.removeCareReminder(item);if(mounted)setState((){});}},itemBuilder:(_)=>const [PopupMenuItem(value:'snooze',child:Text('تعویق یک‌ساعته')),PopupMenuItem(value:'delete',child:Text('حذف یادآوری'))]))),
 const SizedBox(height:12),const Text('نکته آزمایشی: زمان‌های داخل ساعات سکوت به اولین زمان مجاز بعد از پایان سکوت منتقل می‌شوند. تکرارهای روزانه و هفتگی با ساعت محلی گوشی تنظیم می‌شوند.',style:TextStyle(fontSize:12,color:Colors.black54))
 ]));}
}

class Trend extends StatefulWidget{
 const Trend({super.key,required this.app});
 final DnbState app;
 @override State<Trend> createState()=>TrendState();
}
class TrendState extends State<Trend>{
 String? selectedId;
 @override Widget build(BuildContext c){
  final plants=widget.app.plants;
  if(plants.isEmpty)return Scaffold(appBar:AppBar(title:const Text('نمودار وضعیت')),body:const Center(child:Text('هنوز گیاهی ثبت نشده است')));
  selectedId??=plants.first.id;
  final plant=plants.firstWhere((p)=>p.id==selectedId,orElse:()=>plants.first);
  final cutoff=DateTime.now().subtract(const Duration(days:90));
  final entries=plant.history.where((h){final d=DateTime.tryParse((h['date']??'').toString());return d!=null&&!d.isBefore(cutoff);}).toList()
   ..sort((a,b)=>(a['date']??'').toString().compareTo((b['date']??'').toString()));
  return Scaffold(appBar:AppBar(title:const Text('نمودار وضعیت')),body:ListView(padding:const EdgeInsets.all(16),children:[
   DropdownButtonFormField<String>(value:plant.id,decoration:const InputDecoration(labelText:'انتخاب گیاه',border:OutlineInputBorder()),items:plants.map((p)=>DropdownMenuItem(value:p.id,child:Text(p.name))).toList(),onChanged:(v)=>setState(()=>selectedId=v)),
   const SizedBox(height:14),
   Text('روند وضعیت ${plant.name} در ۹۰ روز اخیر',style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
   const SizedBox(height:8),
   if(entries.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('در سه ماه اخیر وضعیتی ثبت نشده است. از شناسنامه گیاه، «ثبت وضعیت جدید» را انتخاب کن.')))
   else Card(elevation:0,child:Padding(padding:const EdgeInsets.fromLTRB(8,16,8,8),child:SizedBox(height:230,child:CustomPaint(painter:PlantTrendPainter(entries),size:const Size(double.infinity,230))))),
   const SizedBox(height:10),
   const Text('مقیاس کیفی: نیازمند بررسی، ضعیف، متوسط، خوب، عالی. این نمودار فقط وضعیت‌های ثبت‌شده را نمایش می‌دهد و پیش‌بینی سلامت نیست.',style:TextStyle(fontSize:11,color:Colors.black54)),
   const Divider(height:28),
   const Text('سوابق ثبت‌شده',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
   for(final h in entries.reversed)ListTile(leading:const Icon(Icons.history,color:green),title:Text((h['condition']??'').toString()),subtitle:Text((h['date']??'').toString().split('T').first+'  '+(h['notes']??''))),
  ]));
 }
}
class PlantTrendPainter extends CustomPainter{
 PlantTrendPainter(this.entries);
 final List<Map<String,dynamic>> entries;
 static const labels=['نیازمند بررسی','ضعیف','متوسط','خوب','عالی'];
 int level(String value)=>switch(value){'عالی'=>5,'خوب'=>4,'متوسط'=>3,'ضعیف'=>2,_=>1};
 @override void paint(Canvas canvas,Size size){
  const left=68.0,right=12.0,top=14.0,bottom=34.0;
  final w=size.width-left-right,h=size.height-top-bottom;
  final grid=Paint()..color=Colors.black12..strokeWidth=1;
  final line=Paint()..color=green..strokeWidth=2.8..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;
  final dot=Paint()..color=green..style=PaintingStyle.fill;
  for(var i=0;i<5;i++){
   final y=top+h-(i*h/4);
   canvas.drawLine(Offset(left,y),Offset(left+w,y),grid);
   final tp=TextPainter(text:TextSpan(text:labels[i],style:const TextStyle(fontSize:10,color:Colors.black54)),textDirection:TextDirection.rtl)..layout(maxWidth:left-6);
   tp.paint(canvas,Offset(left-tp.width-6,y-tp.height/2));
  }
  if(entries.isEmpty)return;
  final path=Path();
  for(var i=0;i<entries.length;i++){
   final x=entries.length==1?left+w/2:left+(i*w/(entries.length-1));
   final y=top+h-((level((entries[i]['condition']??'').toString())-1)*h/4);
   if(i==0)path.moveTo(x,y);else path.lineTo(x,y);
  }
  if(entries.length>1)canvas.drawPath(path,line);
  for(var i=0;i<entries.length;i++){
   final x=entries.length==1?left+w/2:left+(i*w/(entries.length-1));
   final y=top+h-((level((entries[i]['condition']??'').toString())-1)*h/4);
   canvas.drawCircle(Offset(x,y),4.5,dot);
  }
  for(final pair in [0,entries.length-1].toSet()){
   final date=(entries[pair]['date']??'').toString().split('T').first;
   final tp=TextPainter(text:TextSpan(text:date,style:const TextStyle(fontSize:9,color:Colors.black54)),textDirection:TextDirection.ltr)..layout();
   final x=pair==0?left:left+w-tp.width;
   tp.paint(canvas,Offset(x,top+h+8));
  }
 }
 @override bool shouldRepaint(covariant PlantTrendPainter old)=>old.entries!=entries;
}
class Propagation extends StatefulWidget{const Propagation({super.key,required this.app});final DnbState app;@override State<Propagation> createState()=>PropagationState();}
class PropagationState extends State<Propagation>{
 static const Map<String,Map<String,String>> methods={
 'گل حنا':{'m':'قلمه ساقه نرم ← بذر','s':'بهار تا اوایل تابستان','d':'قلمه ۷–۱۰ سانتی‌متری بدون گل را زیر گره ببر، برگ پایین را حذف و در آب یا بستر سبک مرطوب ریشه‌دار کن. بذر را سطحی بکار.','w':'قلمه را از آفتاب مستقیم و گرمای شدید دور نگه دار.'},
 'پونه':{'m':'تقسیم ریشه/ساقه رونده ← قلمه ساقه ← بذر','s':'بهار و پاییز','d':'بخش ریشه‌دار یا ساقه رونده را جدا و مستقیم بکار. قلمه ۸–۱۲ سانتی‌متری را زیر گره ببر. بذر روش کندتر و کم‌اطمینان‌تری است.','w':'گسترش ریشه زیاد است؛ در گلدان مستقل تکثیر کن.'},
 'شمعدانی هلندی':{'m':'قلمه ساقه نیمه‌خشبی ← بذر','s':'بهار یا اواخر تابستان','d':'قلمه ۸–۱۲ سانتی‌متری بدون گل بگیر؛ برگ‌های پایینی را حذف کن و پس از خشک‌شدن مختصر محل برش در بستر سبک بکار. بذر صفات رقم را تضمین نمی‌کند.','w':'بستر خیس و تهویه ضعیف موجب پوسیدگی می‌شود.'},
 'آزالیا':{'m':'قلمه نیمه‌خشبی ← خوابانیدن شاخه ← بذر','s':'اواخر بهار تا تابستان','d':'قلمه ۵–۸ سانتی‌متری از رشد جدیدِ سفت‌شونده در بستر اسیدی سبک و مرطوب ریشه‌دار کن. شاخه انعطاف‌پذیر را خوابانده و پس از ریشه‌زایی جدا کن.','w':'قلمه آزالیا کندریشه است؛ بستر اسیدی و رطوبت محیطی بالا لازم است.'},
 'برگ عبایی':{'m':'تقسیم ریزوم','s':'بهار، هنگام تعویض گلدان','d':'ریزوم را با ابزار ضدعفونی‌شده تقسیم کن؛ هر قطعه باید حداقل یک برگ سالم و چند ریشه داشته باشد.','w':'قطعات کوچک و بدون ریشه دیر مستقر می‌شوند.'},
 'اسپاتی‌فیلوم':{'m':'تقسیم بوته ← بذر (غیرمعمول)','s':'بهار تا اوایل تابستان','d':'توده ریشه را تقسیم کن؛ هر بخش باید چند برگ و ریشه مستقل داشته باشد. بذر تنها پس از گرده‌افشانی و تشکیل بذر قابل استفاده است.','w':'پس از تقسیم، نور غیرمستقیم و رطوبت یکنواخت بده.'},
 'فیلودندرون':{'m':'قلمه ساقه دارای گره ← خوابانیدن هوایی ← پاجوش ریشه‌دار','s':'بهار و تابستان','d':'قلمه باید گره زنده داشته باشد؛ گره را در آب یا بستر سبک قرار بده. برای ساقه بلند از خزه مرطوب دور گره استفاده کن. پاجوش را فقط با ریشه مستقل جدا کن.','w':'روش دقیق به رونده یا خودایستا بودن رقم وابسته است.'},
 'فیلودندرون پرتقالی':{'m':'پاجوش ریشه‌دار ← قلمه گره‌دار در صورت وجود ساقه','s':'بهار تا اوایل تابستان','d':'پاجوش کنار پایه را فقط در صورت داشتن ریشه مستقل جدا کن. برگ یا دمبرگ بدون گره گیاه جدید قابل اتکا نمی‌سازد.','w':'در انواع خودایستا، تقسیم پایه از قلمه برگ مطمئن‌تر است.'},
 'فیلودندرون کنگویی':{'m':'پاجوش/تقسیم پایه ← قلمه ساقه گره‌دار','s':'بهار و اوایل تابستان','d':'پاجوش ریشه‌دار را با کمترین آسیب جدا کن. قلمه ساقه باید گره زنده داشته باشد.','w':'برگ یا دمبرگ به‌تنهایی برای تکثیر کافی نیست.'},
 'آگلونما':{'m':'قلمه ساقه ← تقسیم بوته/پاجوش ← بذر','s':'بهار و تابستان','d':'ساقه بلند را به قطعات چندگره‌ای تقسیم و در بستر گرم و سبک ریشه‌دار کن. پاجوش ریشه‌دار را هنگام تعویض گلدان جدا کن.','w':'هنگام برش دستکش بپوش؛ شیره گیاه ممکن است محرک باشد.'},
 'کاملیا':{'m':'قلمه نیمه‌خشبی ← پیوند ارقام خاص ← خوابانیدن هوایی ← بذر','s':'اواخر بهار تا تابستان','d':'قلمه از رشد همان سال که پایه‌اش کمی سفت شده بگیر؛ در بستر اسیدی متخلخل و مرطوب قرار بده. برای ارقام دشوارریشه‌زا پیوند تخصصی مناسب است.','w':'قلمه کاملیا کندریشه است؛ گرما و اشباع خاک مضر است.'},
 'کالانکوآ':{'m':'قلمه ساقه ← قلمه برگ','s':'بهار تا تابستان','d':'قلمه ساقه ۵–۸ سانتی‌متری را جدا و ۱–۲ روز خشک کن، سپس در بستر کاکتوس بکار. برگ سالم را روی بستر سبک قرار بده تا گیاهچه بسازد.','w':'آبیاری محدود؛ بستر خیس باعث پوسیدگی می‌شود.'},
 'سرخس فوجر':{'m':'تقسیم بوته/ریزوم ← ساقه رونده ریشه‌دار ← هاگ (تخصصی)','s':'بهار، آغاز رشد','d':'توده ریشه را تقسیم کن؛ هر قسمت تاج رشد و ریشه سالم داشته باشد. اگر گیاهچه ریشه‌دار روی ساقه رونده دارد جدا کن.','w':'نام رایج ممکن است به چند گونه اشاره کند؛ برای تشخیص دقیق عکس لازم است.'},
 'ریحان بنفش':{'m':'بذر ← قلمه ساقه در آب','s':'بهار تا اوایل تابستان','d':'بذر را حدود نیم سانتی‌متر بپوشان. برای قلمه، سرشاخه ۸–۱۲ سانتی‌متری را زیر گره ببر و در آب تمیز ریشه‌دار کن.','w':'برای تعداد زیاد بذر اقتصادی‌تر؛ برای حفظ ویژگی بوته مادر قلمه.'},
 'نعنا فلفلی':{'m':'تقسیم ریشه/استولون ← قلمه ساقه ← بذر','s':'بهار و پاییز برای تقسیم','d':'ساقه رونده ریشه‌دار را جدا و در خاک مرطوب بکار. قلمه ۸–۱۰ سانتی‌متری را در آب ریشه‌دار کن. بذر ممکن است ویژگی رقم را حفظ نکند.','w':'در گلدان مستقل نگه دار؛ ریشه‌ها سریع گسترش می‌یابند.'},
 'نخل اریکا':{'m':'بذر تازه و رسیده','s':'بهار و تابستان گرم','d':'بذر تازه را از پوسته گوشتی پاک و در بستر استریل و سبک بکار؛ گرمای بستر و رطوبت یکنواخت لازم است.','w':'تقسیم دسته‌ای توصیه نمی‌شود؛ ریشه‌ها و تنه‌ها به هم وابسته‌اند.'},
 'کاج لاوسون':{'m':'قلمه انتهایی نیمه‌خشبی/چوبی ← بذر','s':'اواخر تابستان تا پاییز برای قلمه','d':'قلمه انتهایی شاخه جانبی را با پاشنه کوچک جدا و در بستر شنی-پیت مرطوب ریشه‌دار کن. بذر ممکن است به سرمادهی نیاز داشته باشد.','w':'ریشه‌زایی کند؛ از خشک‌شدن قلمه و غرقابی شدن بستر جلوگیری کن.'},
 'به‌لیمو':{'m':'قلمه نیمه‌خشبی ← خوابانیدن شاخه ← بذر','s':'اواخر بهار تا تابستان','d':'قلمه ۸–۱۲ سانتی‌متری بگیر؛ برگ پایین را حذف و در بستر سبک با رطوبت بالا قرار بده. شاخه نزدیک خاک را نیز می‌توان خوابانید.','w':'قلمه را در سایه روشن نگه دار تا پیش از ریشه‌زایی خشک نشود.'},
 'فوشیا':{'m':'قلمه سرشاخه نرم ← قلمه نیمه‌خشبی','s':'بهار و تابستان خنک','d':'سرشاخه بدون گل ۵–۸ سانتی‌متری را زیر گره ببر؛ برگ پایین را حذف و در بستر سبک بکار.','w':'در گرمای کرج قلمه را در سایه روشن و محیط خنک نگه دار.'},
 'گاردنیا':{'m':'قلمه نیمه‌خشبی ← خوابانیدن هوایی ← بذر','s':'اواخر بهار تا تابستان','d':'قلمه ۸–۱۲ سانتی‌متری از شاخه سالم در بستر اسیدی سبک و مرطوب ریشه‌دار کن. برای شاخه بلند خوابانیدن هوایی انجام بده.','w':'بستر اسیدی و مرطوب اما غیرغرقابی لازم است.'},
 'مرجان':{'m':'قلمه ساقه نیمه‌خشبی ← بذر','s':'بهار تا تابستان','d':'شاخه را با دستکش جدا کن؛ شیره سفید را با احتیاط پاک کن و چند روز برای پینه‌بستن محل برش صبر کن، سپس در بستر کاکتوس بکار.','w':'شیره مرجان محرک و سمی است؛ دستکش و محافظ چشم استفاده کن.'},
 'میخک هندی':{'m':'قلمه نیمه‌خشبی ← خوابانیدن هوایی','s':'اواخر بهار تا تابستان','d':'قلمه ۸–۱۰ سانتی‌متری نیمه‌خشبی در بستر سبک با رطوبت بالا ریشه‌دار کن؛ شاخه ضخیم‌تر را می‌توان خوابانید.','w':'این راهنما با فرض Ixora coccinea است؛ اگر گونه دیگری است عکس لازم است.'},
 'فردوس':{'m':'ابتدا شناسایی دقیق گونه','s':'پس از تأیید گونه تعیین می‌شود','d':'نام «فردوس» مبهم است؛ عکس کامل گیاه، برگ و ساقه بفرست. تا شناسایی قطعی قلمه نزن.','w':'اگر منظور افوربیا باشد شیره ممکن است محرک یا سمی باشد.'},
 'دم‌روغ‌روبی':{'m':'ابتدا شناسایی دقیق گونه','s':'پس از تأیید گونه تعیین می‌شود','d':'نام رایج برای تعیین روش تکثیر کافی نیست؛ عکس کامل گیاه و برگ/گل لازم است.','w':'تا تشخیص قطعی، قلمه‌گیری یا تقسیم انجام نده.'}
 };
 late List<String> choices;String? selected;
 @override void initState(){super.initState();choices=(<String>{...methods.keys,...widget.app.plants.map((p)=>p.name)}).toList()..sort();selected=widget.app.plants.isNotEmpty?widget.app.plants.first.name:choices.first;}
 @override Widget build(BuildContext c){final name=selected??choices.first;final g=methods[name]??{'m':'شناسایی گونه و سپس انتخاب روش','s':'پس از شناسایی تعیین می‌شود','d':'این نام در راهنمای گونه‌ای موجود نیست. نام علمی یا عکس واضح از کل گیاه، برگ و ساقه را مشخص کن تا روش‌های مناسب با اولویت واقعی تعیین شوند.','w':'بدون شناخت ساختار رشد گیاه از قلمه یا تقسیم عمومی استفاده نکن.'};final ranks=g['m']!.split(' ← ');return Scaffold(appBar:AppBar(title:const Text('تکثیر تخصصی گیاهان')),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('برای هر گیاه، روش‌ها بر اساس موفقیت عملی، حفظ ویژگی گیاه مادر و سهولت اجرا اولویت‌بندی شده‌اند.',style:TextStyle(color:Colors.black54)),const SizedBox(height:14),DropdownButtonFormField<String>(value:name,isExpanded:true,decoration:const InputDecoration(labelText:'انتخاب گیاه',border:OutlineInputBorder()),items:choices.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>selected=v)),const SizedBox(height:16),Text(name,style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),Text('زمان مناسب: '+g['s']!),const Divider(height:26),const Text('ترتیب اولویت روش‌ها',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:8),for(var i=0;i<ranks.length;i++)Card(elevation:0,child:ListTile(leading:CircleAvatar(backgroundColor:pale,child:Text((i+1).toString(),style:const TextStyle(color:green,fontWeight:FontWeight.bold))),title:Text(ranks[i],style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:i==0?Text(g['d']!):null)),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF4E5),borderRadius:BorderRadius.circular(12)),child:Text('نکته تخصصی: '+g['w']!)),const SizedBox(height:12),const Text('اولویت نهایی با سلامت گیاه مادر، سن، فصل و دمای محل تکثیر تنظیم می‌شود.',style:TextStyle(fontSize:12,color:Colors.black54))]));}
}
class Settings extends StatelessWidget{const Settings({super.key,required this.app});final DnbState app;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تنظیمات')),body:ListView(padding:const EdgeInsets.all(16),children:[
 DropdownButtonFormField<String>(value:app.lang,decoration:const InputDecoration(labelText:'زبان',border:OutlineInputBorder()),items:['فارسی','English','العربية'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){app.lang=v??app.lang;app.save();}),
 SwitchListTile(value:app.reminders,onChanged:(v)=>app.setReminderEnabled(v),title:const Text('یادآوری‌ها'),subtitle:const Text('اعلان‌های واقعی برای زمان‌های ثبت‌شده؛ با امکان فعال و غیرفعال‌سازی')),
 ListTile(title:const Text('ساعات سکوت'),subtitle:Text(app.quiet),trailing:const Icon(Icons.edit),onTap:()async{final x=await showDialog<String>(context:c,builder:(d){final t=TextEditingController(text:app.quiet);return AlertDialog(title:const Text('ساعات سکوت'),content:TextField(controller:t,decoration:const InputDecoration(hintText:'مثلاً ۲۲:۰۰ تا ۰۸:۰۰')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(d,t.text),child:const Text('ذخیره'))]);});if(x!=null){app.updateQuietHours(x);}}),
 const Divider(),const Text('حریم خصوصی',style:TextStyle(fontWeight:FontWeight.bold)),const Text('اطلاعات در حافظه محلی همین گوشی ذخیره می‌شود. حذف برنامه یا پاک‌کردن داده‌ها ممکن است اطلاعات را پاک کند. مکان‌یابی و آب‌وهوا با اجازه شما فعال می‌شوند؛ تشخیص گیاه به کلید Pl@ntNet نیاز دارد. تحلیل خودکار تصویر خاک هنوز فعال نشده است.')
 ]));
}
