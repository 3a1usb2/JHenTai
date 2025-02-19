import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jhentai/src/config/ui_config.dart';
import 'package:jhentai/src/extension/string_extension.dart';
import 'package:jhentai/src/extension/widget_extension.dart';
import 'package:jhentai/src/service/local_gallery_service.dart';
import 'package:jhentai/src/setting/download_setting.dart';
import 'package:jhentai/src/setting/user_setting.dart';
import 'package:jhentai/src/utils/toast_util.dart';
import 'package:jhentai/src/widget/eh_wheel_speed_controller.dart';
import 'package:jhentai/src/widget/loading_state_indicator.dart';
import 'package:path/path.dart';

import '../../../routes/routes.dart';
import '../../../service/archive_download_service.dart';
import '../../../service/gallery_download_service.dart';
import '../../../utils/log.dart';
import '../../../utils/permission_util.dart';
import '../../../utils/route_util.dart';

class SettingDownloadPage extends StatefulWidget {
  const SettingDownloadPage({Key? key}) : super(key: key);

  @override
  State<SettingDownloadPage> createState() => _SettingDownloadPageState();
}

class _SettingDownloadPageState extends State<SettingDownloadPage> {
  final GalleryDownloadService galleryDownloadService = Get.find();
  final ArchiveDownloadService archiveDownloadService = Get.find();
  final LocalGalleryService localGalleryService = Get.find();

  LoadingState changeDownloadPathState = LoadingState.idle;

  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('downloadSetting'.tr)),
      body: Obx(
        () => EHWheelSpeedController(
          controller: scrollController,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.only(top: 16),
            children: [
              _buildDownloadPath(),
              if (!GetPlatform.isIOS) _buildResetDownloadPath(),
              _buildExtraGalleryScanPath(),
              if (GetPlatform.isDesktop) _buildSingleImageSavePath(),
              _buildDownloadOriginalImage(),
              _buildDownloadConcurrency(),
              _buildSpeedLimit(context),
              _buildTimeout(),
              _buildDownloadAllGallerysOfSamePriority(),
              _buildDeleteArchiveFileAfterDownload(),
              _buildRestore(),
            ],
          ).withListTileTheme(context),
        ),
      ),
    );
  }

  Widget _buildDownloadPath() {
    return ListTile(
      title: Text('downloadPath'.tr),
      subtitle: Text(DownloadSetting.downloadPath.value.breakWord),
      trailing: changeDownloadPathState == LoadingState.loading ? const CupertinoActivityIndicator() : null,
      onTap: () {
        if (!GetPlatform.isIOS) {
          toast('changeDownloadPathHint'.tr, isShort: false);
        }
      },
      onLongPress: _handleChangeDownloadPath,
    );
  }

  Widget _buildResetDownloadPath() {
    return ListTile(
      title: Text('resetDownloadPath'.tr),
      subtitle: Text('longPress2Reset'.tr),
      onLongPress: _handleResetDownloadPath,
    );
  }

  Widget _buildExtraGalleryScanPath() {
    return ListTile(
      title: Text('extraGalleryScanPath'.tr),
      subtitle: Text('extraGalleryScanPathHint'.tr),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => toRoute(Routes.extraGalleryScanPath),
    );
  }

  Widget _buildSingleImageSavePath() {
    return ListTile(
      title: Text('singleImageSavePath'.tr),
      subtitle: Text(DownloadSetting.singleImageSavePath.value.breakWord),
      trailing: GetPlatform.isMacOS ? null : const Icon(Icons.keyboard_arrow_right),
      onTap: GetPlatform.isMacOS ? null : _handleChangeSingleImageSavePath,
    );
  }

  Widget _buildDownloadOriginalImage() {
    return ListTile(
      title: Text('downloadOriginalImageByDefault'.tr),
      trailing: Switch(
        value: DownloadSetting.downloadOriginalImageByDefault.value ?? false,
        onChanged: (value) {
          if (!UserSetting.hasLoggedIn()) {
            toast('needLoginToOperate'.tr);
            return;
          }
          DownloadSetting.saveDownloadOriginalImageByDefault(value);
        },
      ),
    );
  }

  Widget _buildDownloadConcurrency() {
    return ListTile(
      title: Text('downloadTaskConcurrency'.tr),
      trailing: DropdownButton<int>(
        value: DownloadSetting.downloadTaskConcurrency.value,
        elevation: 4,
        onChanged: (int? newValue) => DownloadSetting.saveDownloadTaskConcurrency(newValue!),
        items: const [
          DropdownMenuItem(child: Text('2'), value: 2),
          DropdownMenuItem(child: Text('4'), value: 4),
          DropdownMenuItem(child: Text('6'), value: 6),
          DropdownMenuItem(child: Text('8'), value: 8),
          DropdownMenuItem(child: Text('10'), value: 10),
        ],
      ),
    );
  }

  Widget _buildSpeedLimit(BuildContext context) {
    return ListTile(
      title: Text('speedLimit'.tr),
      subtitle: Text('speedLimitHint'.tr),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<int>(
            value: DownloadSetting.maximum.value,
            elevation: 4,
            alignment: AlignmentDirectional.bottomEnd,
            onChanged: (int? newValue) {
              DownloadSetting.saveMaximum(newValue!);
            },
            items: const [
              DropdownMenuItem(child: Text('1'), value: 1),
              DropdownMenuItem(child: Text('2'), value: 2),
              DropdownMenuItem(child: Text('3'), value: 3),
              DropdownMenuItem(child: Text('5'), value: 5),
              DropdownMenuItem(child: Text('10'), value: 10),
              DropdownMenuItem(child: Text('99'), value: 99),
            ],
          ),
          Text('${'images'.tr} ${'per'.tr}', style: UIConfig.settingPageListTileTrailingTextStyle(context)).marginSymmetric(horizontal: 8),
          DropdownButton<Duration>(
            value: DownloadSetting.period.value,
            elevation: 4,
            alignment: AlignmentDirectional.bottomEnd,
            onChanged: (Duration? newValue) => DownloadSetting.savePeriod(newValue!),
            items: const [
              DropdownMenuItem(child: Text('1s'), value: Duration(seconds: 1)),
              DropdownMenuItem(child: Text('2s'), value: Duration(seconds: 2)),
              DropdownMenuItem(child: Text('3s'), value: Duration(seconds: 3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeout() {
    return ListTile(
      title: Text('downloadTimeout'.tr),
      trailing: DropdownButton<int>(
        value: DownloadSetting.timeout.value,
        elevation: 4,
        onChanged: (int? newValue) => DownloadSetting.saveTimeout(newValue!),
        items: const [
          DropdownMenuItem(child: Text('5s'), value: 5),
          DropdownMenuItem(child: Text('10s'), value: 10),
          DropdownMenuItem(child: Text('15s'), value: 15),
          DropdownMenuItem(child: Text('20s'), value: 20),
          DropdownMenuItem(child: Text('30s'), value: 30),
          DropdownMenuItem(child: Text('60s'), value: 60),
          DropdownMenuItem(child: Text('180s'), value: 180),
        ],
      ),
    );
  }

  Widget _buildDownloadAllGallerysOfSamePriority() {
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('downloadAllGallerysOfSamePriority'.tr),
          const SizedBox(width: 2),
          const Icon(Icons.help, size: 18),
        ],
      ),
      subtitle: Text('needRestart'.tr),
      trailing: Switch(
        value: DownloadSetting.downloadAllGallerysOfSamePriority.value,
        onChanged: DownloadSetting.saveDownloadAllGallerysOfSamePriority,
      ),
      onTap: () => toast('downloadAllGallerysOfSamePriorityHint'.tr, isShort: false),
    );
  }

  Widget _buildDeleteArchiveFileAfterDownload() {
    return ListTile(
      title: Text('deleteArchiveFileAfterDownload'.tr),
      trailing: Switch(value: DownloadSetting.deleteArchiveFileAfterDownload.value, onChanged: DownloadSetting.saveDeleteArchiveFileAfterDownload),
    );
  }

  Widget _buildRestore() {
    return ListTile(
      title: Text('restoreDownloadTasks'.tr),
      subtitle: Text('restoreDownloadTasksHint'.tr),
      onTap: _restore,
    );
  }

  Future<void> _handleChangeDownloadPath({String? newDownloadPath}) async {
    if (changeDownloadPathState == LoadingState.loading) {
      return;
    }

    if (GetPlatform.isIOS) {
      return;
    }

    await requestPermission();

    String oldDownloadPath = DownloadSetting.downloadPath.value;

    /// choose new download path
    try {
      newDownloadPath ??= await FilePicker.platform.getDirectoryPath();
    } on Exception catch (e) {
      Log.error('Pick download path failed', e);
    }

    if (newDownloadPath == null || newDownloadPath == oldDownloadPath) {
      return;
    }

    /// check permission
    if (!checkPermissionForPath(newDownloadPath)) {
      toast('invalidPath'.tr, isShort: false);
      return;
    }

    setState(() => changeDownloadPathState = LoadingState.loading);

    try {
      await Future.wait([
        galleryDownloadService.pauseAllDownloadGallery(),
        archiveDownloadService.pauseAllDownloadArchive(),
      ]);

      try {
        await _copyOldFiles(oldDownloadPath, newDownloadPath);
      } on Exception catch (e) {
        Log.error('Copy files failed!', e);
        Log.upload(e, extraInfos: {'oldDownloadPath': oldDownloadPath, 'newDownloadPath': newDownloadPath});
        toast('internalError'.tr);
      }

      DownloadSetting.saveDownloadPath(newDownloadPath);

      /// to be compatible with the previous version, update the database.
      await galleryDownloadService.updateImagePathAfterDownloadPathChanged();

      await localGalleryService.refreshLocalGallerys();
    } on Exception catch (e) {
      Log.error('_handleChangeDownloadPath failed!', e);
      Log.upload(e);
      toast('internalError'.tr);
    } finally {
      setState(() => changeDownloadPathState = LoadingState.idle);
    }
  }

  Future<void> _handleResetDownloadPath() {
    return _handleChangeDownloadPath(newDownloadPath: DownloadSetting.defaultDownloadPath);
  }

  Future<void> _copyOldFiles(String oldDownloadPath, String newDownloadPath) async {
    io.Directory oldDownloadDir = io.Directory(oldDownloadPath);
    List<io.FileSystemEntity> oldEntities = oldDownloadDir.listSync(recursive: true);
    List<io.Directory> oldDirs = oldEntities.whereType<io.Directory>().toList();
    List<io.File> oldFiles = oldEntities.whereType<io.File>().toList();

    List<Future> futures = [];

    /// copy directories first
    for (io.Directory oldDir in oldDirs) {
      io.Directory newDir = io.Directory(join(newDownloadPath, relative(oldDir.path, from: oldDownloadPath)));
      futures.add(newDir.create(recursive: true));
    }
    await Future.wait(futures);
    futures.clear();

    /// then copy files
    for (io.File oldFile in oldFiles) {
      futures.add(oldFile.copy(join(newDownloadPath, relative(oldFile.path, from: oldDownloadPath))));
    }
    await Future.wait(futures);
  }

  Future<void> _handleChangeSingleImageSavePath() async {
    String oldPath = DownloadSetting.singleImageSavePath.value;
    String? newPath;

    /// choose new path
    try {
      newPath = await FilePicker.platform.getDirectoryPath();
    } on Exception catch (e) {
      Log.error('Pick single image save path failed', e);
    }

    if (newPath == null || newPath == oldPath) {
      return;
    }

    /// check permission
    if (!checkPermissionForPath(newPath)) {
      toast('invalidPath'.tr, isShort: false);
      return;
    }

    DownloadSetting.saveSingleImageSavePath(newPath);
  }

  Future<void> _restore() async {
    Log.info('Restore download task.');

    int restoredGalleryCount = await Get.find<GalleryDownloadService>().restoreTasks();
    int restoredArchiveCount = await Get.find<ArchiveDownloadService>().restoreTasks();

    toast(
      '${'restoredGalleryCount'.tr}: $restoredGalleryCount\n${'restoredArchiveCount'.tr}: $restoredArchiveCount',
      isShort: false,
    );
  }
}
