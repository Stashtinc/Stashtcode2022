import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stasht/memories/controllers/memories_controller.dart';
import 'package:stasht/memories/domain/memories_model.dart';
import 'package:stasht/routes/app_routes.dart';
import 'package:stasht/utils/app_colors.dart';
import 'package:stasht/utils/assets_images.dart';

class Step1 extends GetView<MemoriesController> with WidgetsBindingObserver {
  int val = -1;
  bool isEmail = false;

  Step1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    var argument = Get.arguments;

    return Scaffold(
        body: SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Obx(
          () => Padding(
              padding: const EdgeInsets.only(top: 50, left: 25, right: 25),
              child:  !controller.showPermissions.value
                  ? Column(
                      children: [
                        Expanded(
                          child: Column(children: [
                            Center(
                              child: Center(
                                  child: SvgPicture.asset(
                                stashtLogo,
                              )),
                            ),
                            const SizedBox(
                              height: 100,
                            ),
                            if (argument == "yes")
                              const Text(
                                "Step 1",
                                style: TextStyle(
                                    fontSize: 21,
                                    color: AppColors.primaryColor,
                                    fontFamily: gibsonRegular),
                              ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              argument == "yes"
                                  ? "Create your first memory folder"
                                  : "Memory folder name",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontFamily: robotoMedium),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Obx(
                              () => Focus(
                                autofocus: false,
                                child: TextFormField(
                                  controller: controller.titleController,

                                  decoration: InputDecoration(
                                      hintText: controller.hasFocus.value
                                          ? ""
                                          : "E.g. Wedding Photos",
                                      hintStyle: const TextStyle(
                                          color: AppColors.hintTextColor,
                                          fontSize: 34,
                                          fontFamily: robotoBold),
                                      border: InputBorder.none,
                                      alignLabelWithHint: true,
                                      contentPadding: const EdgeInsets.only(
                                          bottom: 10, top: 5)),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 34,
                                      fontFamily: robotoBold),
                                  // readOnly: true,
                                  textAlign: TextAlign.center,
                                  onChanged: (text) {
                                    if (text.isNotEmpty) {
                                      controller.showNext.value = true;
                                    } else {
                                      controller.showNext.value = false;
                                    }
                                  },
                                ),
                                onFocusChange: (hasFocus) {
                                  controller.hasFocus.value = hasFocus;
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ]),
                        ),
                        Obx(
                          () => Visibility(
                            maintainAnimation: true,
                            maintainSize: false,
                            maintainState: true,
                            visible: controller.showNext.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (argument == "yes") {
                                        Get.offNamed(AppRoutes.memories);
                                      } else {
                                        Get.back();
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 3.0, vertical: 8),
                                      child: Text(
                                        "Cancel",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontFamily: gibsonRegular),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      // controller.promptPermissionSetting();
                                      // controller.update();
                                      // Get.toNamed(AppRoutes.memoriesStep2, arguments: {
                                      //   "title": controller.titleController.value.text,
                                      //   "fromSignup": argument
                                      // });
                                      MemoriesModel? memoriesModel = null;
                                      controller.pickImages("", memoriesModel);
                                    },
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 11),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              "Next",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontFamily: gibsonSemiBold),
                                            ),
                                            Padding(
                                                padding:
                                                    EdgeInsets.only(left: 5),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white,
                                                  size: 10,
                                                ))
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (argument == "yes")
                          InkWell(
                            onTap: () {
                              Get.offNamed(AppRoutes.memories);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Skip this step",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color.fromRGBO(108, 96, 255, 1),
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(
                          height: 10,
                        )
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(25),
                      height: MediaQuery.of(context).size.height,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.permissionStatus.value ==
                                        PermissionStatus.permanentlyDenied ||
                                    controller.permissionStatus.value ==
                                        PermissionStatus.limited
                                ? 'Please grant Photos permission from settings to create memory'
                                : 'Please grant Photos permission to create memory',
                            style: const TextStyle(
                                fontSize: 21,
                                color: Colors.black,
                                fontFamily: gibsonSemiBold),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          InkWell(
                            onTap: () async {
                              print(
                                  'controller.permissionStatus.value  ${controller.permissionStatus.value}');
                              if (controller.permissionStatus.value ==
                                      PermissionStatus.granted &&
                                  controller.permissionStatus.value ==
                                      PermissionStatus.limited) {
                                controller.promptPermissionSetting();
                              } else {
                                var object =
                                    await AppSettings.openAppSettings();

                                controller.promptPermissionSetting();
                              }
                            },
                            child: Container(
                              height: 42,
                              width: 200,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(22)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    "Allow permission",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: gibsonSemiBold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ))),
        ),
      ),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    print('Resume ${state}');
    if (state == AppLifecycleState.resumed) {
      controller.promptPermissionSettings();
    }
  }
}
