package com.rossofuoco.personale.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = RossoAccent,
    onPrimary = Color.Black,
    primaryContainer = RossoPrimaryDark,
    onPrimaryContainer = Color.White,
    secondary = RossoSecondary,
    onSecondary = Color.White,
    background = DarkBackground,
    onBackground = TextPrimaryDark,
    surface = DarkSurface,
    onSurface = TextPrimaryDark
)

private val LightColorScheme = lightColorScheme(
    primary = RossoPrimary,
    onPrimary = Color.White,
    primaryContainer = RossoContainer,
    onPrimaryContainer = OnRossoContainer,
    secondary = RossoSecondary,
    onSecondary = Color.White,
    background = LightBackground,
    onBackground = TextPrimaryLight,
    surface = LightSurface,
    onSurface = TextPrimaryLight
)

@Composable
fun RossoFuocoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
