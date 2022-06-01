import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stasht/utils/app_colors.dart';
import 'package:stasht/utils/assets_images.dart';
import 'package:stasht/utils/constants.dart';

PreferredSizeWidget commonAppbar(
    BuildContext context, String title, 
    {required Function(
            bool isMemory, bool isPhotos, bool isNotification, bool isSettings)
        pageSelected}) {
  return AppBar(
    backgroundColor: Colors.white,
    centerTitle: false,
    automaticallyImplyLeading: false,
    title: Row(
      children: [
        InkWell(
          onTap: () {
            pageSelected(false, false, false, false);
          },
          child: SvgPicture.asset(
            folderIcon,
            width: 24,
            height: 20,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(
          width: 30,
        ),
        InkWell(
          onTap: () {
            pageSelected(false, true, false, false);
          },
          child: SvgPicture.asset(
            "assets/images/todayapp.svg",
            height: 22,
            width: 21,
            color: const Color.fromRGBO(108, 96, 255, 1),
          ),
        ),
        const SizedBox(
          width: 55,
        ),
        Expanded(
          child: Container(
            height: 30,
            alignment: Alignment.center,
            child: Text(
              title,
              style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontFamily: gibsonSemiBold,
                  fontSize: 22),
            ),
          ),
        ),
      ],
    ),
    actions: [
      Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(
              width: 30,
            ),
            Stack(
              children: [
                InkWell(
                  onTap: () {
                    pageSelected(false, false, true, false);
                  },
                  child: SvgPicture.asset(
                    "assets/images/bell.svg",
                    height: 22,
                    width: 21,
                    color: const Color.fromRGBO(108, 96, 255, 1),
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 15,
            ),
            InkWell(
              onTap: () {
                pageSelected(false, false, false, true);
              },
              child: CircleAvatar(
                radius: 18,
                child: ClipRRect(
                  child: userImage.isNotEmpty
                      ? CachedNetworkImage(imageUrl: userImage)
                      : Image.asset(
                          "assets/images/photo.jpeg",
                          fit: BoxFit.cover,
                          height: 34,
                          width: 34,
                        ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
            const SizedBox(
              width: 19,
            ),
          ],
        ),
      )
    ],
  );
}
