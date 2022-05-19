import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:stasht/login_signup/domain/user_model.dart';
import 'package:stasht/routes/app_routes.dart';
import 'package:stasht/utils/app_colors.dart';
import 'package:stasht/utils/constants.dart';

class SignupController extends GetxController {
  // var facebookLogin = FacebookLogin();
  final RxBool isObscure = true.obs;

  final formkey = GlobalKey<FormState>();
  final formkeySignin = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  bool? _isLogged;
  bool _fetching = false;

  bool get fetching => _fetching;
  bool? get isLogged => _isLogged;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  final usersRef = FirebaseFirestore.instance
      .collection('users')
      .withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromJson(snapshots.data()!),
        toFirestore: (movie, _) => movie.toJson(),
      );
  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void checkEmailExists() {
    usersRef
        .where("email", isEqualTo: emailController.text.toString())
        .get()
        .then((value) => {
              value.docs.length,
              if (value.docs.isEmpty)
                {signupUser()}
              else
                {
                  Get.snackbar("Email Exists",
                      "This email id is already registered with us, please sign-in!")
                }
            });
  }

// Signup user to app and save session
  Future<void> signupUser() async {
    if (formkey.currentState!.validate()) {
      if (!checkValidEmail(emailController.text.toString())) {
        Get.snackbar("Email Invalid", "Please enter valid email address");
      } else if (passwordController.text.toString().length < 6) {
        Get.snackbar("Password", "Please enter at least 6 characters",
            borderColor: Colors.red);
      } else {
        try {
          EasyLoading.show(status: 'Processing..');

          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          )
              .then((value) {
            print("FirebaseAuthExceptionValue $value");
            saveUserToDB(value.user, userNameController.text);
          }).onError((error, stackTrace) {
            if (error.toString().contains("email-already-in-use")) {
              Get.snackbar(
                "Email exits",
                "The email address is already in use by another account.",
                snackPosition: SnackPosition.BOTTOM,
              );
            }
            EasyLoading.dismiss();
            print("FirebaseAuthExceptionError ${error.toString()}");
          });
        } on FirebaseAuthException catch (e) {
          EasyLoading.dismiss();
          print("FirebaseAuthException $e");
          return;
        }
      }
    }
  }

// Signin user to app and save session
  Future<void> signIn() async {
    if (formkeySignin.currentState!.validate()) {
      if (!checkValidEmail(emailController.text.toString())) {
        Get.snackbar("Email Invalid", "Please enter valid email address");
      } else if (passwordController.text.toString().length < 6) {
        Get.snackbar("Password", "Please enter at least 6 characters",
            borderColor: Colors.red);
      } else {
        try {
          EasyLoading.show(status: 'Processing..');
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text)
              .then((value1) {
            usersRef
                .where("email", isEqualTo: value1.user!.email)
                .get()
                .then((value) => {
                      print(
                          'MyLogin ${value1.user!.email} =>${value.size} ==>'),
                      EasyLoading.dismiss(),
                      if (value.docs.isNotEmpty)
                        {
                          saveSession(
                              value.docs[0].id,
                              value.docs[0].data().userName!,
                              emailController.text,
                              value.docs[0].data().profileImage!),
                          Get.offNamed(AppRoutes.memories)
                        }
                      else
                        {Get.snackbar("Error", "Email not exists!")}
                    });
          });
        } on FirebaseAuthException catch (e) {
          EasyLoading.dismiss();
          if (e.code == 'user-not-found') {
            print("User not found");

            Get.snackbar("Error", "User not found",
                snackPosition: SnackPosition.BOTTOM);
            return Future.error(
                "User Not Found", StackTrace.fromString("User Not Found"));
          } else if (e.code == 'wrong-password') {
            print("Incorrect password");

            Get.snackbar("Error", "Password is incorrect",
                snackPosition: SnackPosition.BOTTOM);
            return Future.error("Incorrect password",
                StackTrace.fromString("Incorrect password"));
          } else {
            print("Login Failed ${e.message}");

            Get.snackbar("Error", "Login Failed! Please try again in some time",
                snackPosition: SnackPosition.BOTTOM);
            return Future.error(
                "Login Failed", StackTrace.fromString("Unknown error"));
          }
        }
      }
    }
  }

//Save user to Firebase

  void saveUserToDB(User? user, String username) {
    UserModel userModel = UserModel(
        userName: username,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        deviceToken: "",
        deviceType: Platform.isAndroid ? "Android" : "IOS",
        displayName: username,
        email: user!.email,
        profileImage: "",
        status: true);

    usersRef.add(userModel).then((value) => {
          EasyLoading.dismiss(),
          print('UsersDB $value'),
          saveSession(value.id, username, user.email!, ""),
          emailController.text = "",
          passwordController.text = "",
          userNameController.text = "",
          Get.snackbar('Success', "User registerd successfully",
              snackPosition: SnackPosition.BOTTOM),
          Get.offNamed(AppRoutes.memories)
        });
  }

// Initialize Facebook
  void _init() async {
    _isLogged = await _facebookAuth.accessToken != null;
    if (_isLogged!) {
      _userData = await _facebookAuth.getUserData(
        fields: "name,email,picture.width(200)",
      );
    }
  }

//Signin to facebook
  Future<bool> facebookLogin() async {
    EasyLoading.show(status: 'Processing');
    _fetching = true;

    final LoginResult result = await _facebookAuth.login();

    _isLogged = result.status == LoginStatus.success;
    print('Status ${result.status}');
    if (_isLogged!) {
      _userData = await _facebookAuth.getUserData();
      print('_userData ${_userData}');
      _fetching = false;
      usersRef
          .where("email", isEqualTo: _userData!['email'])
          .get()
          .then((value) => {
                value.docs.length,
                if (value.docs.isEmpty)
                  {
                    saveUserToFirebase(_userData!['name'], _userData!['email'],
                        _userData!['picture']['data']['url'])
                  }
                else
                  {
                    EasyLoading.dismiss(),
                    emailController.text = "",
                    passwordController.text = "",
                    Get.snackbar('Success', "User logged-in successfully",
                        snackPosition: SnackPosition.BOTTOM),
                    Get.offNamed(AppRoutes.memories)
                  }
              });
    } else {
      EasyLoading.dismiss();
    }

    return _isLogged!;
  }

// Save user to firebase
  void saveUserToFirebase(String? name, String? email, String? profileImage) {
    UserModel userModel = UserModel(
        userName: name!,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        deviceToken: "",
        deviceType: Platform.isAndroid ? "Android" : "IOS",
        displayName: name,
        email: email,
        profileImage: profileImage,
        status: true);

    usersRef.add(userModel).then((value) => {
          EasyLoading.dismiss(),
          saveSession(value.id, name, email!, profileImage!),
          Get.snackbar('Success', "User logged-in successfully",
              snackPosition: SnackPosition.BOTTOM),
          Get.offNamed(AppRoutes.memories)
        });
  }

// Save User Session
  void saveSession(
      String _userId, String _userName, String _userEmail, String _userImage) {
    userId = _userId;
    userEmail = _userEmail;
    userName = _userName;
    userImage = _userImage;
  }

  @override
  void onClose() {
    super.onClose();
    print('OnClose ');
    userNameController.text = "";
    emailController.text = "";
    passwordController.text = "";
  }

  @override
  void onReady() {
    super.onReady();
  }
}
