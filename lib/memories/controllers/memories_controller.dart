import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:get/get.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:stasht/login_signup/domain/user_model.dart';
import 'package:stasht/memories/domain/memories_model.dart';
import 'package:stasht/notifications/domain/notification_model.dart';
import 'package:stasht/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:stasht/utils/constants.dart';

class MemoriesController extends GetxController {
  RxBool showNext = false.obs;
  var mediaPages = List.empty(growable: true).obs;
  var memoriesList = List.empty(growable: true).obs;
  var noData = false.obs;
  RxList sharedMemoriesList = List.empty(growable: true).obs;
  RxList selectionList = List.empty(growable: true).obs;
  RxList selectedIndexList = List.empty(growable: true).obs;
  final titleController = TextEditingController();
  List<Medium> selectedList = List.empty(growable: true);
  int pageCount = 50;
  int totalCount = 0;
  int skip = 0;
  RxInt selectedCount = 0.obs;
  ScrollController controller = ScrollController();
  List<ImagesCaption> imageCaptionUrls = List.empty(growable: true);
  int uploadCount = 0;
  RxBool myMemoriesExpand = false.obs;
  RxBool sharedMemoriesExpand = false.obs;
  Rx<PermissionStatus> permissionStatus = PermissionStatus.denied.obs;
  RxBool hasFocus = false.obs;
  FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;
  List<Asset> images = List<Asset>.empty(growable: true).obs;

  String URI_PREFIX_FIREBASE = "https://stasht.page.link";
  String DEFAULT_FALLBACK_URL_ANDROID = "https://stasht.page.link";
  List<Asset> resultList = List<Asset>.empty(growable: true);
  Rx<Uri> shareLink = Uri().obs;
  @override
  void onInit() {
    super.onInit();

    promptPermissionSetting();

    print('fromShare $fromShare');
    sharedMemoriesExpand.value = fromShare;
    getMyMemories();
    getSharedMemories();
  }

  //get Shared memories
  void getSharedMemories() {
    print('getSharedMemories=> $userId');

    memoriesRef
        .where('shared_with', arrayContainsAny: [
          {'user_id': userId, 'status': 0},
          {'user_id': userId, 'status': 1}
        ])
        .orderBy('created_at', descending: true)
        .get()
        .then((value) => {
              print('sharedvalue $userId => ${value.docs.length}'),
              sharedMemoriesList.clear(),
              value.docs.forEach((element) {
                usersRef.doc(element.data().createdBy!).get().then((userValue) {
                  MemoriesModel memoriesModel = element.data();
                  memoriesModel.memoryId = element.id;
                  memoriesModel.userModel = userValue.data()!;
                  sharedMemoriesList.add(memoriesModel);
                  print('sharedMemoriesList ${sharedMemoriesList.length}');
                  if (element.id == value.docs[value.docs.length - 1].id) {
                    print('Shared ${sharedMemoriesList.length}');
                    update();
                  }
                });
              }),
            })
        .onError((error, stackTrace) => {print('onError $error')});
  }

  void deleteMemory(String memoryId, int removeIndex,
      MemoriesModel memoriesModel, ImagesCaption imagesCaption) {
    List<int> removeItemList = List.empty(growable: true);
    removeItemList.add(removeIndex);
    print('ImageCaption ${removeItemList[0]}');
    MemoriesModel memoriesModels = memoriesModel;
    memoriesModels.imagesCaption!.removeAt(removeIndex);
    memoriesRef.doc(memoryId).update(memoriesModels.toJson()).then((value) => {
          print('Deleted Successfully!'),
          update(),
          if (memoriesModels.imagesCaption!.isEmpty)
            {
              Get.back(),
              memoriesRef
                  .doc(memoryId)
                  .delete()
                  .then((value) => {print('Delete')})
            }
        });
  }

  void updateJoinStatus(
      String memoryID, int isJoined, int index, int shareIndex) {
    MemoriesModel memoriesModel = MemoriesModel();
    memoriesModel = sharedMemoriesList[index];
    memoriesModel.sharedWith![shareIndex].status = isJoined;
    print('MemoryModel ${memoriesModel.toJson()}');
    memoriesRef
        .doc(memoryID)
        .set(memoriesModel)
        .then((value) => {
              sharedMemoriesList[index].sharedWith[shareIndex].status = 1,
              print('update Join Status '),
              update()
            })
        .onError((error, stackTrace) => {EasyLoading.dismiss()});
  }

  void updateInviteLink(MemoriesModel model, String inviteLink) {
    MemoriesModel memoriesModel = MemoriesModel();
    memoriesModel = model;
    memoriesModel.inviteLink = inviteLink;
    memoriesRef
        .doc(model.memoryId)
        .set(memoriesModel)
        .then((value) => {
              print('update Invite Link '),

              // Get.back()
            })
        .onError((error, stackTrace) => {EasyLoading.dismiss()});
  }

  void getMyMemories() {
    memoriesList.clear();
    print('userId $userId');

    memoriesRef
        .where('created_by', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((value) => {
              print('value $userId => ${value.docs.length}'),
              noData.value = value.docs.isNotEmpty,
              memoriesList.clear(),
              value.docs.forEach((element) {
                // getUserData(element.data().createdBy!);
                usersRef.doc(userId).get().then(
                  (userValue) {
                    MemoriesModel memoriesModel = element.data();
                    memoriesModel.memoryId = element.id;
                    memoriesModel.userModel = userValue.data()!;
                    memoriesList.value.add(memoriesModel);
                    
                    if (element.id == value.docs[value.docs.length - 1].id) {

                      myMemoriesExpand.value = !sharedMemoriesExpand.value;
                      print('MyMemoriesExpanded ${myMemoriesExpand.value}');

                      update();
                    }
                  },
                );
              })
            });
  }

  void shareMemory(index) {
    List<SharedWith> sharedList = List.empty(growable: true);

    MemoriesModel memoriesModel = MemoriesModel();
    memoriesModel = memoriesList[index];
    sharedList = memoriesList[index].sharedWith;
    // sharedList.add(SharedWith(userId: ))

    // memoriesModel.sharedWith = caption;
    EasyLoading.show(status: 'Processing');
    memoriesRef
        .doc(memoriesList[index].memoryId)
        .set(memoriesModel)
        .then((value) =>
            {print('UpdateCaption '), EasyLoading.dismiss(), Get.back()})
        .onError((error, stackTrace) => {EasyLoading.dismiss()});
  }

// Create Dynamic Link
  Future<void> createDynamicLink(String memoryId, bool short, int index) async {
    String link = "$DEFAULT_FALLBACK_URL_ANDROID?memory_id=$memoryId";
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: URI_PREFIX_FIREBASE,
      link: Uri.parse(link),
      androidParameters: const AndroidParameters(
        packageName: 'com.app.stasht',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.app.stasht2',
        minimumVersion: '1',
      ),
    );

    if (short) {
      final ShortDynamicLink shortLink =
          await dynamicLinks.buildShortLink(parameters);
      shareLink.value = shortLink.shortUrl;
    } else {
      shareLink.value = await dynamicLinks.buildLink(parameters);
    }

    // share(memoryId, url.toString(), index);
  }

  // Pick Images from gallery
  Future<void> pickImages(String memoryId, MemoriesModel? memoriesModel) async {
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: false,
        selectedAssets: images,
      );
    } on Exception catch (e) {
      print(e);
    }
    // images = resultList;
    uploadImagesToMemories(0, memoryId, memoriesModel);
  }

  // Share Dynamic Link
  Future<void> share(MemoriesModel memoriesModel, String shareText) async {
    await FlutterShare.share(
        title: memoriesModel.title!,
        linkUrl: shareText,
        chooserTitle: 'Share memory folder via..');
    updateInviteLink(memoriesModel, shareText);
  }

  final memoriesRef = FirebaseFirestore.instance
      .collection(memoriesCollection)
      .withConverter<MemoriesModel>(
        fromFirestore: (snapshots, _) =>
            MemoriesModel.fromJson(snapshots.data()!),
        toFirestore: (memories, _) => memories.toJson(),
      );

  final notificationsRef = FirebaseFirestore.instance
      .collection(notificationsCollection)
      .withConverter<NotificationsModel>(
        fromFirestore: (snapshots, _) =>
            NotificationsModel.fromJson(snapshots.data()!),
        toFirestore: (notifications, _) => notifications.toJson(),
      );

  final usersRef = FirebaseFirestore.instance
      .collection(userCollection)
      .withConverter<UserModel>(
        fromFirestore: (snapshots, _) => UserModel.fromJson(snapshots.data()!),
        toFirestore: (users, _) => users.toJson(),
      );

  // Get User Data
  getUserData(String userId) async {
    return await usersRef.doc(userId).get();
  }

  void deleteCollaborator(String memoryId, MemoriesModel memoriesModel,
      int shareIndex, int mainIndex, String type) {
    memoriesModel.sharedWith!.removeAt(shareIndex);
    memoriesRef
        .doc(memoryId)
        .set(memoriesModel)
        .then((value) => debugPrint('DeleteCollaborator'));
    if (type == "1") {
      memoriesList[mainIndex] = memoriesModel;
    } else {
      sharedMemoriesList[mainIndex] = memoriesModel;
    }
  }

  Future<void> acceptInviteNotification(
      String receiverId, String memoryID, MemoriesModel memoriesModel) async {
    var receiverToken = "";
    var db = await FirebaseFirestore.instance
        .collection("users")
        .where("user_id", isEqualTo: receiverId)
        .get();
    db.docs.forEach((element) {
      receiverToken = element.data()['firebase_token'];
    });
    String title = "Invite Accepted";
    String description = "$userName has accepted your invite for memory.";
    // String receiverToken = globalNotificationToken;
    var dataPayload = jsonEncode({
      'to': receiverToken,
      'data': {
        "type": "message",
        "priority": "high",
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "sound": "default",
        "senderId": userId,
        "memoryID": memoryID
      },
      'notification': {
        'title': title,
        'body': description,
        "badge": "1",
        "sound": "default"
      },
    });
    sendPushMessage(receiverToken, dataPayload);
    saveNotificationData(receiverId, memoriesModel);
  }

  // Save Notification data in DB
  void saveNotificationData(String receivedId, MemoriesModel memoriesModel) {
    String memoryCover = memoriesModel.imagesCaption!.isNotEmpty
        ? memoriesModel.imagesCaption![0].image!
        : "";
    NotificationsModel notificationsModel = NotificationsModel(
        memoryTitle: memoriesModel.title,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isRead: false,
        memoryCover: memoryCover,
        memoryId: memoriesModel.memoryId,
        receiverId: receivedId,
        userId: userId);
    notificationsRef
        .add(notificationsModel)
        .then((value) => print('SaveNotification $value'));
  }

  List<SharedWith> getSharedUsers(MemoriesModel memoriesModels) {
    List<SharedWith> sharedModels = List.empty(growable: true);
    if (memoriesModels.sharedWith!.isNotEmpty) {
      int index = 0;
      var shareObject = memoriesModels.sharedWith!.where(
        (element) {
          index = memoriesModels.sharedWith!.indexOf(element);
          return element.status == 1;
        },
      );
      sharedModels.add(shareObject.elementAt(index));
    }
    return sharedModels;
  }

  // check and request permission
  Future<bool> promptPermissionSetting() async {
    var status;
    Permission permission;
    if (Platform.isIOS) {
      permission = Permission.photos;
      if (await permission.isGranted) {
        // Either the permission was already granted before or the user just granted it.
        status = await permission.status;
        permissionStatus.value = status;
        // getAlbums();
        return true;
      } else if (await permission.isLimited) {
        // Either the permission was already granted before or the user just granted it.
        status = await permission.status;
        permissionStatus.value = status;
        // getAlbums();
        return true;
      } else {
        status = await Permission.photos.status;
        permissionStatus.value = status;
        // getAlbums();
        return true;
      }
      // status = await Permission.photos.status;
    } else {
      permission = Permission.storage;
      status = await Permission.storage.status;
      permissionStatus.value = status;
      return true;
    }
    permissionStatus.value = status;
    print('promptPermissionSetting $status');

    // if (status == PermissionStatus.granted ||
    //     status == PermissionStatus.limited) {
    //   print('granteddd');
    //   // update();
    //   getAlbums();
    //   return true;
    // } else
    if (status == PermissionStatus.permanentlyDenied) {
      print('checkkkkkk $status');
      checkPermission();
    } else {
      print('checkkkkkk_Else $status');
      checkPermission();
    }

    return false;
  }

// Check Photos and gallery permission
  checkPermission() async {
    var status;
    if (Platform.isIOS) {
      await Permission.photos
          .request()
          .then((value) => print('Request_photos ${value}'));
    } else {
      await Permission.storage
          .request()
          .then((value) => print('Request_storage ${value}'));
    }
    permissionStatus.value = status;
    print('checkPermission $status');
    return status = PermissionStatus.granted;
  }

// Go To Step 1
  void createMemoriesStep1() {
    Get.toNamed(AppRoutes.memoriesStep1);
  }

//Get Media from Albums
  Future<void> getAlbums() async {
    final List<Album> imageAlbums =
        await PhotoGallery.listAlbums(mediumType: MediumType.image);

    for (int i = 0; i < imageAlbums.length; i++) {
      print('Albums ${imageAlbums[i]}');
      if (imageAlbums[i].name == "All" || imageAlbums[i].name == "Recent") {
        print('imageAlbums[i] ${imageAlbums[i]}');
        getListData(imageAlbums[i]);
        // paginationData(imageAlbums[i]);
      }
    }
  }

  void paginationData(Album album) {
    controller.addListener(() {
      if (controller.position.maxScrollExtent == controller.position.pixels) {
        if (album.name == "All" || album.name == "Recent") {
          if (skip < totalCount) {
            skip = skip + pageCount;
            getListData(album);
          }

          // pageCount+=50;
        }
      }
    });
  }

  // get Images from albums
  void getListData(Album album) async {
    mediaPages.value.clear();
    MediaPage imagePage = await album.listMedia(
      newest: true,
    );

    totalCount = imagePage.total;
    selectionList = List.filled(totalCount, false).obs;
    print('imagePage.items ${imagePage.items}');
    mediaPages.value.addAll(imagePage.items);
    update();
  }

  // Get Total count of selected items
  void getSelectedCount() {
    selectedCount.value = 0;
    selectionList.fold(
        false,
        (previousValue, element) => {
              if (element)
                {
                  print(
                      'element $element <==> ${selectionList.indexOf(element)}'),
                  selectedCount.value += 1,
                  // selectedIndexList.add(selectionList.indexOf(element))
                }
            });
  }

  void addIndex(int index, bool selected) {
    if (selected) {
      selectedIndexList.add(index);
    } else {
      selectedIndexList.remove(index);
    }
  }

  Future<void> uploadImagesToMemories(
      int imageIndex, String memoryId, MemoriesModel? memoriesModel) async {
    if (resultList.isNotEmpty) {
      if (imageIndex == 0) {
        EasyLoading.show(status: 'Uploading...');
      }
      //selectedIndexList = index of selected items from main photos list
      final dir = await path_provider.getTemporaryDirectory();
      final File file = await getImageFileFromAssets(resultList[imageIndex]);
      String fileName = "/temp${DateTime.now().millisecond}.jpg";
      final targetPath = dir.absolute.path + fileName;

      final File? newFile = await testCompressAndGetFile(file, targetPath);
      final UploadTask? uploadTask =
          await uploadFile(newFile!, fileName, memoryId, memoriesModel);
    } else {
      Get.snackbar('Error', "Please select images");
    }
  }

  Future<File> getImageFileFromAssets(Asset asset) async {
    final byteData = await asset.getByteData();

    final tempFile =
        File("${(await getTemporaryDirectory()).path}/${asset.name}");
    final file = await tempFile.writeAsBytes(
      byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );

    return file;
  }

  Future<void> uploadImagesToMemoriesOld(
      int imageIndex, String memoryId, MemoriesModel memoriesModel) async {
    if (selectedIndexList.length > 0) {
      if (imageIndex == 0) {
        EasyLoading.show(status: 'Uploading...');
      }
      //selectedIndexList = index of selected items from main photos list
      final dir = await path_provider.getTemporaryDirectory();

      final File file =
          await mediaPages[selectedIndexList[imageIndex]].getFile();
      final targetPath =
          dir.absolute.path + "/temp${DateTime.now().millisecond}.jpg";

      final File? newFile = await testCompressAndGetFile(file, targetPath);
      final UploadTask? uploadTask = await uploadFile(
          newFile!,
          mediaPages[selectedIndexList[imageIndex]].filename,
          memoryId,
          memoriesModel);
    } else {
      Get.snackbar('Error', "Please select images");
    }
  }

  /// The user selects a file, and the task is added to the list.
  Future<UploadTask?> uploadFile(File file, String fileName, String memoryId,
      MemoriesModel? memoriesModel) async {
    UploadTask uploadTask;
    print('fileName $fileName');
    // Create a Reference to the file
    Reference ref =
        FirebaseStorage.instance.ref().child('memories').child('/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'picked-file-path': file.path,
      },
    );

    print('metaData ${metadata.customMetadata}');

    uploadTask = ref.putFile(io.File(file.path), metadata);
    uploadTask.whenComplete(() => {
          uploadTask.snapshot.ref.getDownloadURL().then((value) => {
                print('URl $value'),
                imageCaptionUrls.add(ImagesCaption(
                    caption: "",
                    image: value,
                    commentCount: 0,
                    imageId:
                        Timestamp.now().millisecondsSinceEpoch.toString())),
                if (imageCaptionUrls.length < resultList.length)
                  {
                    uploadCount += 1,
                    uploadImagesToMemories(
                        uploadCount, memoryId, memoriesModel),
                  }
                else
                  {
                    EasyLoading.dismiss(),
                    if (memoriesModel == null)
                      {createMemories()}
                    else
                      {updateMemory(memoryId, memoriesModel)}
                  }
              })
        });

    return Future.value(uploadTask);
  }

// Update or Add images to existing memory
  void updateMemory(String memoryId, MemoriesModel? memoriesModel) {
    MemoriesModel memoriesModels = memoriesModel!;

    memoriesModels.imagesCaption!.addAll(imageCaptionUrls);
    memoriesRef.doc(memoryId).update(memoriesModels.toJson()).then((value) => {
          print('Updated Successfully!'),
          update(),
          if (memoriesModels.imagesCaption!.isEmpty)
            {
              Get.back(),
            }
        });
  }

  Future<File?> testCompressAndGetFile(File file, String targetPath) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
      minWidth: 600,
      minHeight: 600,
    );
    return result;
  }

  // Create memories to Firebase
  void createMemories() {
    List<SharedWith> shareList = List.empty(growable: true);
    EasyLoading.show(status: 'Creating Memory');
    MemoriesModel memoriesModel = MemoriesModel(
        title: titleController.text.toString(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        createdBy: userId,
        imagesCaption: imageCaptionUrls,
        inviteLink: "",
        published: false,
        commentCount: 0,
        sharedWith: shareList);
    memoriesRef
        .add(memoriesModel)
        .then((value) => {
              EasyLoading.dismiss(),
              Get.snackbar('Success', 'Memory folder created successfully'),
              Get.offAllNamed(AppRoutes.memories)
            })
        .onError((error, stackTrace) => {EasyLoading.dismiss()});
  }

  void saveCaption(
      String caption, int captionIndex, String docId, int mainIndex) {
    print('caption $caption => $docId $captionIndex');
    MemoriesModel memoriesModel = MemoriesModel();
    memoriesModel = memoriesList[mainIndex];

    memoriesModel.imagesCaption![captionIndex].caption = caption;
    EasyLoading.show(status: 'Processing');
    memoriesRef
        .doc(docId)
        .set(memoriesModel)
        .then((value) =>
            {print('UpdateCaption '), EasyLoading.dismiss(), Get.back()})
        .onError((error, stackTrace) => {EasyLoading.dismiss()});
  }

  void deleteInvite(MemoriesModel sharedMemories, int mainIndex) {
    MemoriesModel memoriesModel = sharedMemories;
    print('MemoryID: ${memoriesModel.memoryId}');
    int shareIndex = 0;

    var shareObject = sharedMemories.sharedWith!.where(
      (element) {
        shareIndex = sharedMemories.sharedWith!.indexOf(element);

        return element.userId == userId;
      },
    );

    memoriesModel.sharedWith!.removeAt(shareIndex);
    memoriesRef.doc(sharedMemories.memoryId).set(memoriesModel).then((value) =>
        {
          print('MemoryDeleted'),
          sharedMemoriesList.removeAt(mainIndex),
          update()
        });
  }
}
