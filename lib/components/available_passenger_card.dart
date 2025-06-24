import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';

class AvailablePassengerCard extends StatelessWidget {
  final String name;
  final String location;
  final String phoneNumber;
  final String imageUrl;
  final double rating;
  final VoidCallback onAccept;
  final VoidCallback? onReject;

  const AvailablePassengerCard({
    super.key,
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.imageUrl,
    required this.rating,
    required this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header com avatar e informações principais
            Row(
              children: [
                // Avatar do passageiro
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Informações do passageiro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e avaliação
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingStars(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      
                      // Localização
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botões de ação
            Row(
              children: [
                if (onReject != null) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Rejeitar',
                      onPressed: onReject,
                      variant: ButtonVariant.secondary,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CustomButton(
                    text: 'Aceitar',
                    onPressed: onAccept,
                    variant: ButtonVariant.primary,
                    height: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFD700),
          size: 12,
        );
      }),
    );
  }
}
