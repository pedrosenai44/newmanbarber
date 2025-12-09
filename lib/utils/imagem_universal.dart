import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagemUniversal extends StatelessWidget {
  final String? urlOuBase64;
  final File? arquivoLocal;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  const ImagemUniversal({
    super.key,
    this.urlOuBase64,
    this.arquivoLocal,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prioridade: Arquivo Local (Preview antes de salvar)
    if (arquivoLocal != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(arquivoLocal!, width: width, height: height, fit: fit),
      );
    }

    // 2. Se for nulo ou vazio, mostra ícone padrão
    if (urlOuBase64 == null || urlOuBase64!.isEmpty) {
      return _buildPlaceholder();
    }

    // 3. Verifica se é Link da Web (http/https)
    if (urlOuBase64!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: urlOuBase64!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => _buildPlaceholder(erro: true),
        ),
      );
    }

    // 4. Tenta decodificar como Base64 (Texto salvo no banco)
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.memory(
          base64Decode(urlOuBase64!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(erro: true),
        ),
      );
    } catch (e) {
      return _buildPlaceholder(erro: true);
    }
  }

  Widget _buildPlaceholder({bool erro = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        erro ? Icons.broken_image : Icons.image,
        color: Colors.grey,
        size: (width != null && width! > 50) ? 40 : 20,
      ),
    );
  }
}
