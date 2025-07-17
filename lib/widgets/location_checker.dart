import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuccessIstirahatDialog extends StatelessWidget {
  const SuccessIstirahatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width < 600;
    final isVerySmallHeight = screenSize.height < 600;

    // Responsive values
    final horizontalMargin = isSmallScreen ? 12.0 : 20.0;
    final dialogPadding = isSmallScreen ? 12.0 : (isMediumScreen ? 20.0 : 30.0);
    final iconSize = isSmallScreen ? 60.0 : (isMediumScreen ? 70.0 : 80.0);
    final checkIconSize = isSmallScreen ? 25.0 : (isMediumScreen ? 30.0 : 35.0);
    final titleFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 28.0);
    final messageFontSize = isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 16.0);
    final buttonHeight = isSmallScreen ? 44.0 : 50.0;

    // Vertical spacing adjustments
    final topSpacing = isVerySmallHeight ? 20.0 : (isSmallScreen ? 25.0 : 40.0);
    final afterIconSpacing = isVerySmallHeight ? 15.0 : (isSmallScreen ? 20.0 : 30.0);
    final afterTitleSpacing = isVerySmallHeight ? 10.0 : (isSmallScreen ? 15.0 : 20.0);
    final afterMessageSpacing = isVerySmallHeight ? 8.0 : (isSmallScreen ? 12.0 : 15.0);
    final beforeButtonSpacing = isVerySmallHeight ? 15.0 : (isSmallScreen ? 20.0 : 35.0);
    final bottomSpacing = isVerySmallHeight ? 15.0 : (isSmallScreen ? 20.0 : 30.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: isVerySmallHeight ? 20 : 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMediumScreen ? screenSize.width * 0.9 : 400,
          maxHeight: screenSize.height * (isVerySmallHeight ? 0.9 : 0.8),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar at top
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                SizedBox(height: topSpacing),

                // Success icon with decorative elements
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decoration circle
                    Container(
                      width: iconSize + 15,
                      height: iconSize + 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),

                    // Main success badge
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: checkIconSize,
                      ),
                    ),

                    // Decorative star elements - responsive positioning
                    if (!isVerySmallHeight) ...[
                      Positioned(
                        top: 0,
                        right: isSmallScreen ? 8 : 12,
                        child: Container(
                          width: isSmallScreen ? 14 : 18,
                          height: isSmallScreen ? 14 : 18,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: isSmallScreen ? 8 : 10,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 3,
                        left: isSmallScreen ? 5 : 8,
                        child: Container(
                          width: isSmallScreen ? 12 : 14,
                          height: isSmallScreen ? 12 : 14,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star,
                            color: Colors.white,
                            size: isSmallScreen ? 6 : 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: afterIconSpacing),

                // Success title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: dialogPadding),
                  child: Text(
                    'HOORAAY!',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: isSmallScreen ? 0.8 : 1.2,
                    ),
                  ),
                ),

                SizedBox(height: afterTitleSpacing),

                // Success message
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: dialogPadding),
                  child: Text(
                    'Anda telah istirahat mulai jam $currentTime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: messageFontSize,
                      color: Colors.grey,
                      height: 1.3,
                    ),
                  ),
                ),

                SizedBox(height: afterMessageSpacing),

                // Reminder message with special styling
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 6 : 8
                  ),
                  margin: EdgeInsets.symmetric(horizontal: dialogPadding),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mosque,
                        color: Colors.green.shade700,
                        size: isSmallScreen ? 12 : 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'jangan lupa sholat!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: beforeButtonSpacing),

                // OK Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: dialogPadding),
                  child: SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonHeight / 2),
                        ),
                        elevation: 2,
                        shadowColor: Colors.teal.withOpacity(0.3),
                      ),
                      child: Text(
                        'Ya, Mengerti',
                        style: TextStyle(
                          fontSize: messageFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method untuk menampilkan dialog
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return const SuccessIstirahatDialog();
      },
    );
  }
}