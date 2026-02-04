import 'dart:io';
import 'package:flutter/material.dart';

sealed class ArtworkState {}

class ArtworkInitial extends ArtworkState {}

class ArtworkLoading extends ArtworkState {}

class ArtworkError extends ArtworkState {
  final String message;
  ArtworkError([this.message = "Unknown error"]);
}

class ArtworkVisible extends ArtworkState {
  final File image;
  final Color backgroundColor;
  final Color effectColor;

  ArtworkVisible({
    required this.image,
    required this.backgroundColor,
    required this.effectColor,
  });
}
