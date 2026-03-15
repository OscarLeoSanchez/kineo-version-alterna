import 'package:flutter/material.dart';

/// Design tokens de color para Kineo Coach.
/// Todos los Color(0xFF...) del proyecto deben referenciar esta clase.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF143C3A); // teal oscuro principal
  static const primaryLight = Color(0xFFD6EEE6); // teal claro / chips
  static const primaryMid = Color(0xFF1A4A47); // gradiente start
  static const primaryDark = Color(0xFF0F2E2C); // gradiente end
  static const primaryAlt = Color(0xFF2B6A66); // variante media gradiente
  static const primaryDeep = Color(0xFF173836); // teal muy oscuro gradiente
  static const primaryTeal = Color(0xFF2A6A65); // teal éxito / completado
  static const primarySubtle = Color(0xFF2F6E67); // teal intermedio claro

  // ── Surface / Background ───────────────────────────────────────────────────
  static const surface = Color(0xFFF5F0E6); // fondo beige cálido
  static const surfaceAlt = Color(0xFFF1ECE3); // variante más clara
  static const surfaceCard = Color(0xFFF6F1E8); // cards sobre fondo
  static const surfaceMuted = Color(0xFFF7F2E8); // fondo tarjeta muted
  static const surfaceWarm = Color(0xFFF7F1E7); // fondo cálido alternativo
  static const surfaceCream = Color(0xFFF8F5EF); // crema suave
  static const surfaceCanvas = Color(0xFFF5EFE4); // canvas principal AppTheme
  static const surfaceClay = Color(0xFFE8D8BF); // clay chips AppTheme
  static const surfaceMist = Color(0xFFE6EFE8); // mist indicador nav

  // ── Brand Light Variants ───────────────────────────────────────────────────
  static const brandLight = Color(0xFFE7EFEA); // teal muy claro (nutrition_page local)
  static const brandLightAlt = Color(0xFFE8EFE8); // teal muy claro (workout_page chip)
  static const primarySelected = Color(0xFFDCEBE4); // seleccionado teal
  static const primaryBg = Color(0xFFDDEBE5); // fondo sección teal claro
  static const primaryXLight = Color(0xFFDCECE4); // extra claro teal

  // ── Accent / Success ───────────────────────────────────────────────────────
  static const accent = Color(0xFF2E7D52); // verde éxito
  static const accentLight = Color(0xFFE8F4EE); // verde muy claro
  static const accentMid = Color(0xFFDCF0E4); // verde claro chips
  static const accentChip = Color(0xFFE7F4EE); // verde chip claro
  static const accentBg = Color(0xFFDFF0E6); // verde fondo seleccionado
  static const accentDivider = Color(0xFFB8DCC8); // divisor verde
  static const accentSubtle = Color(0xFF9DC7AD); // verde grisáceo (logged)
  static const accentSuccess = Color(0xFF4CAF50); // verde success progreso
  static const accentBlue = Color(0xFF2D7FF9); // azul proteínas macro

  // ── Warning / Amber ────────────────────────────────────────────────────────
  static const warning = Color(0xFFB45309); // ámbar texto
  static const warningLight = Color(0xFFFFF3CD); // ámbar fondo chip
  static const warningBg = Color(0xFFFEF3C7); // ámbar fondo sección
  static const warningAmber = Color(0xFFF59E0B); // ámbar icono / indicador
  static const warningGold = Color(0xFFD97706); // ámbar dorado
  static const warningPale = Color(0xFFFFF6DB); // ámbar muy claro
  static const warningBorder = Color(0xFFF3E1A6); // ámbar borde
  static const warningChip = Color(0xFFFCE9A8); // ámbar chip interior
  static const warningWarm = Color(0xFFFFEDCC); // ámbar cálido
  static const warningPeach = Color(0xFFFFF3E0); // melocotón claro
  static const warningOrange = Color(0xFFFF6B35); // naranja esfuerzo/alerta
  static const warningGoldDark = Color(0xFFCF9B57); // dorado oscuro gradiente
  static const warningAmberChip = Color(0xFFFFE7BE); // ámbar chip claro

  // ── Error / Red ───────────────────────────────────────────────────────────
  static const error = Color(0xFFEF5350); // rojo error / exceso
  static const errorDark = Color(0xFFDC2626); // rojo error oscuro
  static const errorLight = Color(0xFFFFE8E8); // rojo fondo suave
  static const errorPale = Color(0xFFFFE4E4); // rojo muy claro

  // ── Info / Blue ───────────────────────────────────────────────────────────
  static const info = Color(0xFF1565C0); // azul texto
  static const infoLight = Color(0xFFE3F2FD); // azul fondo chip
  static const infoSoft = Color(0xFFE8EAF6); // índigo muy claro
  static const infoPale = Color(0xFFDCE9FF); // azul muy pálido
  static const infoBorder = Color(0xFFD8DDEA); // borde azulado

  // ── Purple / Violet ───────────────────────────────────────────────────────
  static const purple = Color(0xFF7C3AED); // violeta accent
  static const purpleLight = Color(0xFFE8E4F4); // lila claro chip
  static const purplePale = Color(0xFFE6DFEC); // lila muy claro

  // ── Neutral ───────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1C1C1E); // texto principal
  static const textInk = Color(0xFF172221); // tinta AppTheme
  static const textSecondary = Color(0xFF4D5B59); // texto secundario AppTheme
  static const textMuted = Color(0xFF6B7A79); // texto apagado workout
  static const textDisabled = Color(0xFFAFB8C1); // texto deshabilitado
  static const iconMuted = Color(0xFF5B6663); // icono nav no seleccionado
  static const divider = Color(0xFFE5E7EB); // divisor suave
  static const dividerWarm = Color(0xFFD8D2C7); // divisor cálido AppTheme
  static const cardBorder = Color(0xFFE0E5DE); // borde card verde muy suave
  static const cardBorderWarm = Color(0xFFDAE2DC); // borde cálido
  static const cardBorderMuted = Color(0xFFD8DED7); // borde muted
  static const neutral = Color(0xFFD8D1C4); // gris neutro (kGrey nutrition)
  static const neutralBorder = Color(0xFFD8DCD5); // borde neutral chip
  static const neutralLine = Color(0xFFD9DDD8); // línea sutil
  static const neutralLight = Color(0xFF8A7F73); // neutro claro texto

  // ── Macros ────────────────────────────────────────────────────────────────
  static const macroProtein = Color(0xFFDCEEDC); // verde proteínas
  static const macroCarbsFg = Color(0xFFB45309); // ámbar carbos fg
  static const macroCarbsBg = Color(0xFFFFF3CD); // ámbar carbos bg
  static const macroFat = Color(0xFFE3F2FD); // azul grasas
  static const macroFiber = Color(0xFFDCEEDC); // verde fibra
  static const macroFatAlt = Color(0xFFE8E4F4); // lila grasas alt

  // ── Gradient surface colors ────────────────────────────────────────────────
  static const gradientSurfaceStart = Color(0xFFF5E8D7); // naranja claro start
  static const gradientSurfaceEnd = Color(0xFFE0ECE6); // verde claro end
  static const gradientWarmStart = Color(0xFFF6E8D4); // cálido start
  static const gradientWarmEnd = Color(0xFFE2EFE7); // fresco end

  // ── Gradientes frecuentes ─────────────────────────────────────────────────
  static const Gradient brandGradient = LinearGradient(
    colors: [primaryMid, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient brandGradientAlt = LinearGradient(
    colors: [primaryDeep, primarySubtle],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient brandGradientDark = LinearGradient(
    colors: [primary, primaryAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient surfaceGradient = LinearGradient(
    colors: [gradientSurfaceStart, gradientSurfaceEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF2EEE7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
