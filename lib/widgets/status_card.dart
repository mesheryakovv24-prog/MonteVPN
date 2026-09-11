import 'package:flutter/material.dart';
import '../services/vpn_service.dart';
import '../theme/app_theme.dart';

class StatusCard extends StatelessWidget {
  final MonteVpnService vpnService;

  const StatusCard({Key? key, required this.vpnService}) : super(key: key);

  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 KB/s';
    final kb = bytesPerSecond / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = vpnService.status == ConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            icon: Icons.arrow_downward_rounded,
            iconColor: AppTheme.primaryNeon,
            label: 'Download',
            value: isConnected ? _formatSpeed(vpnService.v2rayStatus.downloadSpeed) : '0 KB/s',
          ),
          Container(
            height: 35,
            width: 1,
            color: AppTheme.cardBorder,
          ),
          _buildItem(
            icon: Icons.arrow_upward_rounded,
            iconColor: AppTheme.accentPurple,
            label: 'Upload',
            value: isConnected ? _formatSpeed(vpnService.v2rayStatus.uploadSpeed) : '0 KB/s',
          ),
          Container(
            height: 35,
            width: 1,
            color: AppTheme.cardBorder,
          ),
          _buildItem(
            icon: Icons.speed_rounded,
            iconColor: isConnected && vpnService.pingDelay > 0 ? AppTheme.successGreen : AppTheme.textMuted,
            label: 'Ping',
            value: isConnected && vpnService.pingDelay > 0 ? '${vpnService.pingDelay} ms' : '--',
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
