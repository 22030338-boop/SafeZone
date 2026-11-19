
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../../authentication/providers/auth_provider.dart';

import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String uid,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return EditNameDialog(initialName: currentName);
      },
    );

    if (newName == null || newName.trim().isEmpty) return;

    try {
      await ref.read(profileServiceProvider).updateName(newName);

      ref.invalidate(profileDataProvider(uid));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre actualizado correctamente.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el nombre: $e'),
        ),
      );
    }
  }


  Future<void> _changePhoto(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final canEditPhoto = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    if (!canEditPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes cambiar la fotografía de esta cuenta.',
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image == null || !context.mounted) return;

      // Mostrar indicador de carga durante la subida.
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return const PopScope(
            canPop: false,
            child: AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text('Subiendo fotografía...'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final photoUrl = await CloudinaryService.uploadFile(image);

      await ref.read(profileServiceProvider).updatePhoto(photoUrl);

      ref.invalidate(profileDataProvider(uid));

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotografía actualizada correctamente.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Cerrar el indicador de carga si está abierto.
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la fotografía: $e'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay una sesión activa.'),
        ),
      );
    }

    final profileAsync = ref.watch(profileDataProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error al cargar el perfil: $error'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('No se encontró tu perfil.'),
            );
          }

          final name =
              profile['name'] as String? ?? 'Usuario SafeZone';

          final email =
              profile['email'] as String? ?? user.email ?? '';

          final photoUrl = profile['photoUrl'] as String?;

          final provider =
              profile['provider'] as String? ?? 'password';

          final canEditPhoto = user.providerData.any(
            (provider) => provider.providerId == 'password',
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage:
                      photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),

                if (canEditPhoto)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton.filled(
                      tooltip: 'Cambiar fotografía',
                      onPressed: () => _changePhoto(
                        context,
                        ref,
                        user.uid,
                      ),
                      icon: const Icon(Icons.camera_alt),
                    ),
                  ),
              ],
            ),
          ),


              const SizedBox(height: 16),

              Center(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 30),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Nombre'),
                      subtitle: Text(name),
                      trailing: IconButton(
                        tooltip: 'Editar nombre',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editName(
                          context,
                          ref,
                          name,
                          user.uid,
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Correo electrónico'),
                      subtitle: Text(email),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Correo verificado'),
                      subtitle: Text(
                        user.emailVerified ? 'Sí' : 'No',
                      ),
                      trailing: Icon(
                        user.emailVerified
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: user.emailVerified
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Método de acceso'),
                      subtitle: Text(provider),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text('Identificador de usuario'),
                      subtitle: Text(
                        user.uid,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Diálogo independiente para editar el nombre.
class EditNameDialog extends StatefulWidget {
  final String initialName;

  const EditNameDialog({
    super.key,
    required this.initialName,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar nombre'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Escribe tu nombre',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _controller.text.trim(),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
