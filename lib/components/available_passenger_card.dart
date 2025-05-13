import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_button.dart';

class AvailablePassengerCard extends StatelessWidget {
  final String name;
  final String location;
  final String phoneNumber;
  final String imageUrl;
  final double rating;
  final VoidCallback onAccept;

  const AvailablePassengerCard({
    super.key,
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.imageUrl,
    required this.rating,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do perfil do passageiro
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                // Remover a tentativa de usar backgroundImage quando imageUrl está vazio
                backgroundImage:
                    imageUrl.isNotEmpty ? _getProfileImage() : null,
                child:
                    imageUrl.isEmpty
                        ? Text(
                          name[0],
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        )
                        : null,
              ),
              const SizedBox(width: 16.0),
              // Informações do passageiro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ajustando Row com problema de overflow para garantir flexibilidade
                    Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        _buildRatingStars(),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Localizada: $location',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Celular: $phoneNumber',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          // Botão de aceitar agora no canto inferior direito
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 80,
              child: CustomButton(
                text: 'Aceitar',
                variant: ButtonVariant.primary,
                onPressed: onAccept,
                height: 40,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    // Não devemos nem tentar carregar uma imagem se o caminho estiver vazio
    if (imageUrl.isEmpty) {
      return null;
    }

    try {
      return AssetImage(imageUrl);
    } catch (e) {
      return null;
    }
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize:
          MainAxisSize
              .min, // Garante que a Row não tente ocupar mais espaço que o necessário
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFD700),
          size: 16,
        );
      }),
    );
  }
}
