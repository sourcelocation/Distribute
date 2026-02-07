import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppIcons {
  static bool get isCupertino => Platform.isIOS || Platform.isMacOS;

  static IconData get logout =>
      isCupertino ? CupertinoIcons.square_arrow_right : Icons.logout;
  static IconData get login =>
      isCupertino ? CupertinoIcons.square_arrow_left : Icons.login;
  static IconData get chevronRight =>
      isCupertino ? CupertinoIcons.chevron_right : Icons.chevron_right;
  static IconData get arrowBack =>
      isCupertino ? CupertinoIcons.back : Icons.arrow_back;
  static IconData get personAdd =>
      isCupertino ? CupertinoIcons.person_add : Icons.person_add_outlined;
  static IconData get folder =>
      isCupertino ? CupertinoIcons.folder : Icons.folder_outlined;
  static IconData get folderOpen =>
      isCupertino ? CupertinoIcons.folder_open : Icons.folder_open;
  static IconData get requests =>
      isCupertino ? CupertinoIcons.mail : Icons.mail_outline;
  static IconData get dns => isCupertino ? CupertinoIcons.globe : Icons.dns;
  static IconData get info =>
      isCupertino ? CupertinoIcons.info : Icons.info_outline;
  static IconData get about =>
      isCupertino ? CupertinoIcons.info_circle : Icons.info;
  static IconData get webhook =>
      isCupertino ? CupertinoIcons.link : Icons.webhook;
  static IconData get volumeOff =>
      isCupertino ? CupertinoIcons.volume_off : Icons.volume_off;
  static IconData get deleteForever =>
      isCupertino ? CupertinoIcons.trash : Icons.delete_forever;
  static IconData get bugReport =>
      isCupertino ? CupertinoIcons.ant : Icons.bug_report;
  static IconData get legal =>
      isCupertino ? CupertinoIcons.doc_text : Icons.gavel;

  static IconData get edit => isCupertino ? CupertinoIcons.pencil : Icons.edit;
  static IconData get account =>
      isCupertino ? CupertinoIcons.person_crop_circle : Icons.account_circle;
  static IconData get check =>
      isCupertino ? CupertinoIcons.check_mark : Icons.check;
  static IconData get downloaded =>
      isCupertino ? CupertinoIcons.arrow_down_circle_fill : Icons.download_done;
  static IconData get checkCircle => isCupertino
      ? CupertinoIcons.check_mark_circled
      : Icons.check_circle_outline;
  static IconData get cloud =>
      isCupertino ? CupertinoIcons.cloud : Icons.cloud_outlined;
  static IconData get downloading =>
      isCupertino ? CupertinoIcons.cloud_download : Icons.cloud_download;
  static IconData get error =>
      isCupertino ? CupertinoIcons.exclamationmark_triangle : Icons.error;
  static IconData get errorOutline =>
      isCupertino ? CupertinoIcons.exclamationmark_circle : Icons.error_outline;

  static IconData get removeCircle =>
      isCupertino ? CupertinoIcons.minus_circle : Icons.remove_circle_outline;
  static IconData get delete =>
      isCupertino ? CupertinoIcons.delete : Icons.delete_outline;
  static IconData get deleteSimple =>
      isCupertino ? CupertinoIcons.delete : Icons.delete;

  static IconData get download =>
      isCupertino ? CupertinoIcons.cloud_download : Icons.download;
  static IconData get share => isCupertino ? CupertinoIcons.share : Icons.share;
  static IconData get move => isCupertino
      ? CupertinoIcons.folder_badge_plus
      : Icons.drive_file_move_outline;
  static IconData get moveSimple =>
      isCupertino ? CupertinoIcons.folder_badge_plus : Icons.drive_file_move;

  static IconData get libraryMusic =>
      isCupertino ? CupertinoIcons.music_note_2 : Icons.library_music;
  static IconData get search =>
      isCupertino ? CupertinoIcons.search : Icons.search;
  static IconData get settings =>
      isCupertino ? CupertinoIcons.settings : Icons.settings;

  static IconData get sync =>
      isCupertino ? CupertinoIcons.arrow_2_circlepath : Icons.sync;
  static IconData get add => isCupertino ? CupertinoIcons.add : Icons.add;
  static IconData get musicNote =>
      isCupertino ? CupertinoIcons.music_note : Icons.music_note;
  static IconData get musicNoteRounded =>
      isCupertino ? CupertinoIcons.music_note_2 : Icons.music_note_rounded;

  static IconData get lock => isCupertino ? CupertinoIcons.lock : Icons.lock;
  static IconData get lockOutline =>
      isCupertino ? CupertinoIcons.lock : Icons.lock_outline;
  static IconData get person =>
      isCupertino ? CupertinoIcons.person : Icons.person;

  static IconData get menu =>
      isCupertino ? CupertinoIcons.list_bullet : Icons.menu;
  static IconData get arrowDown => isCupertino
      ? CupertinoIcons.chevron_down
      : Icons.keyboard_arrow_down_rounded;
  static IconData get fastRewind =>
      isCupertino ? CupertinoIcons.backward_fill : Icons.fast_rewind_rounded;
  static IconData get fastForward =>
      isCupertino ? CupertinoIcons.forward_fill : Icons.fast_forward_rounded;
  static IconData get play =>
      isCupertino ? CupertinoIcons.play_fill : Icons.play_arrow_rounded;
  static IconData get pause =>
      isCupertino ? CupertinoIcons.pause_fill : Icons.pause_rounded;
  static IconData get playSimple =>
      isCupertino ? CupertinoIcons.play_arrow : Icons.play_arrow;
  static IconData get pauseSimple =>
      isCupertino ? CupertinoIcons.pause : Icons.pause;

  static IconData get equalizer =>
      isCupertino ? CupertinoIcons.music_note_list : Icons.equalizer;
  static IconData get warning => isCupertino
      ? CupertinoIcons.exclamationmark_triangle
      : Icons.warning_amber_rounded;
  static IconData get home =>
      isCupertino ? CupertinoIcons.home : Icons.home_rounded;
  static IconData get brush =>
      isCupertino ? CupertinoIcons.paintbrush : Icons.brush;
  static IconData get album =>
      isCupertino ? CupertinoIcons.music_albums : Icons.album;
}
