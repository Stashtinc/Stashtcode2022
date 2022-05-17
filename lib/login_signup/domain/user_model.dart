import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? userName;
  String? email;
  String? displayName;
  String? profileImage;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  bool? status;
  String? deviceType;
  String? deviceToken;

  UserModel(
      {this.userName,
      this.email,
      this.displayName,
      this.profileImage,
      this.createdAt,
      this.updatedAt,
      this.status,
      this.deviceType,
      this.deviceToken});

  UserModel.fromJson(Map<String, dynamic> json) {
    userName = json['user_name'];
    email = json['email'];
    displayName = json['display_name'];
    profileImage = json['profile_image'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    status = json['status'];
    deviceType = json['device_type'];
    deviceToken = json['device_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_name'] = userName;
    data['email'] = email;
    data['display_name'] = displayName;
    data['profile_image'] = profileImage;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['status'] = status;
    data['device_type'] = deviceType;
    data['device_token'] = deviceToken;
    return data;
  }
}
