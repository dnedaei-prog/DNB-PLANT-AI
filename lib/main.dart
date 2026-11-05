import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main()=>runApp(const DnbApp());
const green=Color(0xFF167B62),pale=Color(0xFFE8F4EE);
class Plant{
 Plant({required this.id,required this.name,required this.place,required this.condition,required this.notes,required this.photo,required this.created,required this.active,List<Map<String,dynamic>>? history}):history=history??[];
 final String id,name,place,condition,notes,photo,created;bool active;final List<Map<String,dynamic>> history;
 Map<String,dynamic> json()=>{'id':id,'name':name,'place':place,'condition':condition,'notes':notes,'photo':photo,'created':created,'active':active,'history':history};
 factory Plant.from(Map j)=>Plant(id:j['id']??'',name:j['name']??'',place:j['place']??'',condition:j['condition']??'',notes:j['notes']??'',photo:j['photo']??'',created:j['created']??'',active:j['active']??false,history:List<Map<String,dynamic>>.from((j['history']??[]).map((e)=>Map<String,dynamic>.from(e))));
}
class DnbApp extends StatefulWidget{const DnbApp({super.key});@override State<DnbApp> createState()=>DnbState();}
class DnbState extends State<DnbApp>{
 List<Plant> plants=[];bool ready=false,reminders=true;String lang='فارسی',quiet='۲۲:۰۰ تا ۰۸:۰۰';
 @override void initState(){super.initState();load();}
 Future<void> load()async{final s=await SharedPreferences.getInstance();try{plants=(jsonDecode(s.getString('plants')??'[]') as List).map((e)=>Plant.from(e)).toList();}catch(_){}lang=s.getString('lang')??lang;reminders=s.getBool('reminders')??true;quiet=s.getString('quiet')??quiet;if(mounted)setState(()=>ready=true);}
 Future<void> save()async{final s=await SharedPreferences.getInstance();await s.setString('plants',jsonEncode(plants.map((e)=>e.json()).toList()));await s.setString('lang',lang);await s.setBool('reminders',reminders);await s.setString('quiet',quiet);if(mounted)setState((){});}
 void add(Plant p){setState(()=>plants.insert(0,p));save();}void refresh(){setState((){});save();}
 @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'DNB Plant AI',theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:green),scaffoldBackgroundColor:const Color(0xFFF5F8F5)),home:Directionality(textDirection:TextDirection.rtl,child:ready?Home(app:this):const Scaffold(body:Center(child:CircularProgressIndicator()))));
}
void go(BuildContext c,Widget w)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Directionality(textDirection:TextDirection.rtl,child:w)));
void toast(BuildContext c,String s)=>ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(s)));
class Home extends StatelessWidget{const Home({super.key,required this.app});final DnbState app;
 @override Widget build(BuildContext c){final active=app.plants.where((p)=>p.active).length;final saved=app.plants.length-active;return Scaffold(appBar:AppBar(title:const Text('DNB Plant AI'),centerTitle:true,actions:[IconButton(onPressed:()=>go(c,Settings(app:app)),icon:const Icon(Icons.settings))]),body:ListView(padding:const EdgeInsets.all(16),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xFF125C50),Color(0xFF279B78)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.energy_savings_leaf,color:Colors.white,size:38),SizedBox(height:12),Text('دانا زبان گیاه شما',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)),SizedBox(height:6),Text('همراه ثبت و مراقبت آگاهانه از گیاهان',style:TextStyle(color:Colors.white))])),
 const SizedBox(height:12),Row(children:[stat('گیاهان من',active),const SizedBox(width:8),stat('اطلاعات ذخیره',saved)]),const SizedBox(height:14),
 tile(c,'ثبت جدید','ثبت عکس و وضعیت اولیه',Icons.add_a_photo,()=>go(c,Register(app:app))),
 tile(c,'گیاهان من','شناسنامه مستقل و تاریخچه هر گیاه',Icons.local_florist,()=>go(c,PlantList(app:app,active:true))),
 tile(c,'اطلاعات ذخیره','موارد ذخیره‌شده برای بررسی بعدی',Icons.bookmark,()=>go(c,PlantList(app:app,active:false))),
 tile(c,'تکثیر','راهنمای قلمه، بذر و تقسیم',Icons.content_cut,()=>go(c,const Propagation())),
 tile(c,'گفت‌وگو با دانا','یادداشت و پرسش درباره مراقبت',Icons.chat,()=>go(c,Chat(app:app))),
 tile(c,'نمودار وضعیت','روند ثبت‌های سه ماه اخیر',Icons.show_chart,()=>go(c,Trend(app:app))),
 tile(c,'تنظیمات','زبان، یادآوری و ساعات سکوت',Icons.settings,()=>go(c,Settings(app:app))),
 const SizedBox(height:12),const Text('نسخه آزمایشی محلی • اطلاعات روی همین دستگاه ذخیره می‌شود',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54,fontSize:11))]));}
 Widget stat(String s,int n)=>Expanded(child:Card(elevation:0,child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[Expanded(child:Text(s)),Text(n.toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold))]))));
 Widget tile(BuildContext c,String t,String sub,IconData i,VoidCallback f)=>Card(elevation:0,margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:CircleAvatar(backgroundColor:pale,child:Icon(i,color:green)),title:Text(t,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(sub),trailing:const Icon(Icons.chevron_left),onTap:f));
}
class Register extends StatefulWidget{const Register({super.key,required this.app});final DnbState app;@override State<Register> createState()=>RegisterState();}
class RegisterState extends State<Register>{
 final name=TextEditingController(),notes=TextEditingController();String place='بالکن',condition='متوسط',photo='';bool active=true,busy=false;
 Future<void> pick()async{final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:80,maxWidth:1600);if(x!=null)setState(()=>photo=x.path);}
 Future<void> submit()async{if(name.text.trim().isEmpty){toast(context,'نام گیاه را وارد کن');return;}setState(()=>busy=true);final d=DateTime.now();final p=Plant(id:'DNB-'+d.millisecondsSinceEpoch.toString(),name:name.text.trim(),place:place,condition:condition,notes:notes.text.trim(),photo:photo,created:d.toIso8601String(),active:active,history:[{'date':d.toIso8601String(),'condition':condition,'notes':notes.text.trim()}]);widget.app.add(p);if(!mounted)return;Navigator.pop(context);go(context,Chat(app:widget.app,initial:'برای گیاه '+p.name+' یک یادداشت مراقبتی ثبت کن.'));}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('ثبت جدید')),body:ListView(padding:const EdgeInsets.all(18),children:[
 const Text('شناسنامه اولیه گیاه',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:14),TextField(controller:name,decoration:const InputDecoration(labelText:'نام گیاه یا نام دلخواه',hintText:'مثلاً شمعدانی شماره ۱',border:OutlineInputBorder())),
 const SizedBox(height:12),DropdownButtonFormField<String>(value:place,decoration:const InputDecoration(labelText:'محل نگهداری',border:OutlineInputBorder()),items:['بالکن','داخل منزل','حیاط','گلخانه','سایه','آفتاب مستقیم'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>place=v??place)),
 const SizedBox(height:12),DropdownButtonFormField<String>(value:condition,decoration:const InputDecoration(labelText:'وضعیت اولیه',border:OutlineInputBorder()),items:['عالی','خوب','متوسط','ضعیف','نیازمند بررسی'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>condition=v??condition)),
 const SizedBox(height:12),TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'توضیحات، آبیاری، خاک و نور',border:OutlineInputBorder())),
 const SizedBox(height:12),OutlinedButton.icon(onPressed:pick,icon:const Icon(Icons.photo_library),label:Text(photo.isEmpty?'انتخاب عکس از گالری':'عکس انتخاب شد')),
 if(photo.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(photo),height:180,fit:BoxFit.cover))),
 SwitchListTile(value:active,onChanged:(v)=>setState(()=>active=v),title:const Text('افزودن به «گیاهان من»'),subtitle:const Text('خاموش باشد، فقط در اطلاعات ذخیره می‌ماند')),
 const SizedBox(height:14),FilledButton(onPressed:busy?null:submit,child:const Text('ذخیره شناسنامه'))]));}
}
class PlantList extends StatelessWidget{const PlantList({super.key,required this.app,required this.active});final DnbState app;final bool active;
 @override Widget build(BuildContext c){final items=app.plants.where((p)=>p.active==active).toList();return Scaffold(appBar:AppBar(title:Text(active?'گیاهان من':'اطلاعات ذخیره')),body:items.isEmpty?const Center(child:Text('هنوز موردی ثبت نشده است')):ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){final p=items[i];return Card(elevation:0,child:ListTile(leading:p.photo.isEmpty?const CircleAvatar(child:Icon(Icons.local_florist)):CircleAvatar(backgroundImage:FileImage(File(p.photo))),title:Text(p.name),subtitle:Text(p.place+' • '+p.condition),trailing:const Icon(Icons.chevron_left),onTap:()=>go(c,Profile(app:app,plant:p))));}));}
}
class Profile extends StatefulWidget{const Profile({super.key,required this.app,required this.plant});final DnbState app;final Plant plant;@override State<Profile> createState()=>ProfileState();}
class ProfileState extends State<Profile>{final note=TextEditingController();String condition='خوب';
 @override Widget build(BuildContext c){final p=widget.plant;return Scaffold(appBar:AppBar(title:Text(p.name)),body:ListView(padding:const EdgeInsets.all(16),children:[
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
class ChatState extends State<Chat>{final input=TextEditingController();final messages=<String>[];@override void initState(){super.initState();if(widget.initial.isNotEmpty)messages.add(widget.initial);}
 void send(){final s=input.text.trim();if(s.isEmpty)return;setState((){messages.add('شما: '+s);messages.add('دانا: برای بررسی دقیق‌تر، عکس گیاه و اطلاعات نور، آبیاری و خاک را در شناسنامه ثبت کن. نسخه فعلی هنوز به موتور تشخیص هوشمند و داده‌های آنلاین متصل نیست.');});input.clear();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('گفت‌وگو با دانا')),body:Column(children:[Expanded(child:messages.isEmpty?const Center(child:Text('سلام! درباره گیاهت بنویس یا از شناسنامه آن شروع کن.')):ListView(padding:const EdgeInsets.all(12),children:[for(final m in messages)Card(elevation:0,child:Padding(padding:const EdgeInsets.all(12),child:Text(m)))])),Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:input,onSubmitted:(_)=>send(),decoration:const InputDecoration(hintText:'پیامت را بنویس...',border:OutlineInputBorder()))),IconButton(onPressed:send,icon:const Icon(Icons.send,color:green))]))]));
}
class Trend extends StatelessWidget{const Trend({super.key,required this.app});final DnbState app;
 @override Widget build(BuildContext c){final all=app.plants.expand((p)=>p.history.map((h)=>{'plant':p.name,...h})).toList()..sort((a,b)=>(b['date']??'').toString().compareTo((a['date']??'').toString()));final cut=DateTime.now().subtract(const Duration(days:90));final recent=all.where((h){final d=DateTime.tryParse(h['date']??'');return d!=null&&d.isAfter(cut);}).toList();return Scaffold(appBar:AppBar(title:const Text('نمودار وضعیت')),body:recent.isEmpty?const Center(child:Text('برای نمایش روند، ابتدا وضعیت گیاه را ثبت کن')):ListView(padding:const EdgeInsets.all(12),children:[const Text('ثبت‌های ۹۰ روز اخیر',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),for(final h in recent)Card(elevation:0,child:ListTile(leading:const Icon(Icons.show_chart,color:green),title:Text(h['plant'].toString()+' • '+h['condition'].toString()),subtitle:Text((h['date']??'').toString().split('T').first+'  '+(h['notes']??''))))]));}
}
class Propagation extends StatelessWidget{const Propagation({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تکثیر')),body:const ListView(padding:EdgeInsets.all(16),children:[Text('راهنمای پایه تکثیر',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),SizedBox(height:12),Text('• قلمه ساقه: ابزار تمیز، برش زیر گره و بستر سبک و مرطوب.\n\n• قلمه برگ: فقط برای گونه‌هایی که از برگ تکثیر می‌شوند.\n\n• تقسیم بوته: هر بخش باید ریشه و جوانه مستقل داشته باشد.\n\n• بذر: عمق کاشت، دما و نور به گونه گیاه وابسته است.\n\nاین راهنما عمومی است؛ روش مناسب را برای گونه موردنظر بررسی کن.') ]));}
class Settings extends StatelessWidget{const Settings({super.key,required this.app});final DnbState app;
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('تنظیمات')),body:ListView(padding:const EdgeInsets.all(16),children:[
 DropdownButtonFormField<String>(value:app.lang,decoration:const InputDecoration(labelText:'زبان',border:OutlineInputBorder()),items:['فارسی','English','العربية'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){app.lang=v??app.lang;app.save();}),
 SwitchListTile(value:app.reminders,onChanged:(v){app.reminders=v;app.save();},title:const Text('یادآوری‌ها'),subtitle:const Text('ذخیره تنظیم فعال/غیرفعال؛ اعلان زمان‌بندی‌شده هنوز پیاده‌سازی نشده است')),
 ListTile(title:const Text('ساعات سکوت'),subtitle:Text(app.quiet),trailing:const Icon(Icons.edit),onTap:()async{final x=await showDialog<String>(context:c,builder:(d){final t=TextEditingController(text:app.quiet);return AlertDialog(title:const Text('ساعات سکوت'),content:TextField(controller:t,decoration:const InputDecoration(hintText:'مثلاً ۲۲:۰۰ تا ۰۸:۰۰')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('لغو')),FilledButton(onPressed:()=>Navigator.pop(d,t.text),child:const Text('ذخیره'))]);});if(x!=null){app.quiet=x;app.save();}}),
 const Divider(),const Text('حریم خصوصی',style:TextStyle(fontWeight:FontWeight.bold)),const Text('اطلاعات در حافظه محلی همین گوشی ذخیره می‌شود. حذف برنامه یا پاک‌کردن داده‌ها ممکن است اطلاعات را پاک کند. نسخه فعلی هنوز مکان‌یابی، آب‌وهوا، تشخیص تصویری هوشمند و اعلان خودکار ندارد.')
 ]));
}
