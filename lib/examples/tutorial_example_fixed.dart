// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutorial Demo - Fixed',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late TutorialCoachMark tutorialCoachMark;

  // Define GlobalKeys for each target widget
  final GlobalKey keyTopButton = GlobalKey();
  final GlobalKey keyMenuButton = GlobalKey();
  final GlobalKey keyCenterButton = GlobalKey();
  final GlobalKey keyBottomButton = GlobalKey();
  final GlobalKey keyRightButton = GlobalKey();
  final GlobalKey keyLeftButton = GlobalKey();

  final GlobalKey keyBottomNav1 = GlobalKey();
  final GlobalKey keyBottomNav2 = GlobalKey();
  final GlobalKey keyBottomNav3 = GlobalKey();

  @override
  void initState() {
    super.initState();

    // IMPORTANT: Wait for the first frame to be rendered
    // This ensures all widgets with GlobalKeys are properly built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          createTutorial();
          showTutorial();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial Demo'),
        actions: <Widget>[
          // Menu Button with GlobalKey
          PopupMenuButton(
            key: keyMenuButton, // ✅ Key attached here
            icon: const Icon(Icons.menu),
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text("Option 1")),
              const PopupMenuItem(child: Text("Option 2")),
              const PopupMenuItem(child: Text("Option 3")),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            // Top Button - Big Blue Container
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: keyTopButton, // ✅ Key on the container
                  color: Colors.blue,
                  height: 100,
                  width: MediaQuery.of(context).size.width - 50,
                  child: Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      child: const Icon(Icons.remove_red_eye),
                      onPressed: () {
                        showTutorial();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Center Button
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 50,
                height: 50,
                child: ElevatedButton(
                  key: keyCenterButton, // ✅ Key on the button
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Icon(Icons.star),
                ),
              ),
            ),

            // Bottom Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100.0),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    key: keyBottomButton, // ✅ Key on the button
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Icon(Icons.favorite),
                  ),
                ),
              ),
            ),

            // Right Button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    key: keyRightButton, // ✅ Key on the button
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
            ),

            // Left Button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    key: keyLeftButton, // ✅ Key on the button
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          // Invisible overlay to capture the position of each bottom nav item
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    key: keyBottomNav1, // ✅ Key for first item
                    color: Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    key: keyBottomNav2, // ✅ Key for second item
                    color: Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    key: keyBottomNav3, // ✅ Key for third item
                    color: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          // Actual Bottom Navigation Bar
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business),
                label: 'Business',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: 'School',
              ),
            ],
            selectedItemColor: Colors.amber[800],
            onTap: (index) {
              print('Bottom nav tapped: $index');
            },
          ),
        ],
      ),
    );
  }

  void showTutorial() {
    tutorialCoachMark.show(context: context);
  }

  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.red, // The color of the overlay shadow
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8, // Dark overlay
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        print("Tutorial finished");
      },
      onClickTarget: (target) {
        print('Clicked on target: $target');
      },
      onSkip: () {
        print("Tutorial skipped");
        return true;
      },
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    // Target 1: Menu Button in AppBar
    targets.add(
      TargetFocus(
        identify: "MenuButton",
        keyTarget: keyMenuButton,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.Circle,
        radius: 30,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "قائمة الخيارات",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اضغط هنا لفتح قائمة الخيارات المتاحة",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 2: Top Blue Container Button
    targets.add(
      TargetFocus(
        identify: "TopButton",
        keyTarget: keyTopButton,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        color: Colors.blue,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "زر العرض",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اضغط على هذا الزر لإعادة عرض الدليل التعليمي",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 3: Center Button
    targets.add(
      TargetFocus(
        identify: "CenterButton",
        keyTarget: keyCenterButton,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "الزر المركزي",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "هذا زر مهم في منتصف الشاشة",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 4: Right Button
    targets.add(
      TargetFocus(
        identify: "RightButton",
        keyTarget: keyRightButton,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      "السهم الأيمن",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "استخدم هذا الزر للانتقال إلى اليمين",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 5: Left Button
    targets.add(
      TargetFocus(
        identify: "LeftButton",
        keyTarget: keyLeftButton,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const <Widget>[
                    Text(
                      "السهم الأيسر",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "استخدم هذا الزر للعودة إلى اليسار",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 6: Bottom Button
    targets.add(
      TargetFocus(
        identify: "BottomButton",
        keyTarget: keyBottomButton,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "زر المفضلة",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اضغط لإضافة إلى المفضلة",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 7: Bottom Navigation - Home
    targets.add(
      TargetFocus(
        identify: "BottomNav1",
        keyTarget: keyBottomNav1,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "الصفحة الرئيسية",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "اضغط هنا للعودة إلى الصفحة الرئيسية",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 8: Bottom Navigation - Business
    targets.add(
      TargetFocus(
        identify: "BottomNav2",
        keyTarget: keyBottomNav2,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "الشركات",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "اضغط هنا لعرض قائمة الشركات",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 9: Bottom Navigation - School
    targets.add(
      TargetFocus(
        identify: "BottomNav3",
        keyTarget: keyBottomNav3,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "التعليم",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "اضغط هنا لعرض المحتوى التعليمي",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        controller.previous();
                      },
                      child: const Text('السابق'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    return targets;
  }
}
