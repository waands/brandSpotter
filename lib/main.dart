import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_navigation_bar/responsive_navigation_bar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

/// MyApp é o ponto de entrada da aplicação.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0; // Armazena o índice da aba selecionada

  // Função para trocar de aba, atualizando o estado da interface.
  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Lista de páginas da aplicação que serão exibidas ao trocar as abas.
  final List<Widget> _pages = <Widget>[
    const CameraPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _pages[_selectedIndex], // Mostra a página correspondente à aba.
        bottomNavigationBar: ResponsiveNavigationBar(
          selectedIndex: _selectedIndex,
          onTabChange: changeTab, // Atualiza a aba ativa.
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // Botões da barra de navegação, com ícones e textos.
          navigationBarButtons: const <NavigationBarButton>[
            NavigationBarButton(
              text: 'Camera',
              icon: Icons.camera_alt,
              backgroundGradient: LinearGradient(
                colors: [Colors.yellow, Colors.green, Colors.blue],
              ),
            ),
            NavigationBarButton(
              text: 'Histórico',
              icon: Icons.star,
              backgroundGradient: LinearGradient(
                colors: [Colors.cyan, Colors.teal],
              ),
            ),
            NavigationBarButton(
              text: 'Configurações',
              icon: Icons.settings,
              backgroundGradient: LinearGradient(
                colors: [Colors.green, Colors.yellow],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página da câmera, onde o usuário pode tirar ou selecionar uma foto.
class CameraPage extends StatefulWidget {
  final File? initialImageFile;
  final DateTime? initialPhotoDate;

  const CameraPage({super.key, this.initialImageFile, this.initialPhotoDate});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker imagePicker =
      ImagePicker(); // Instância do picker de imagens
  File? imageFile; // Armazena o arquivo de imagem selecionado
  DateTime? photoDate; // Armazena a data da foto

  @override
  void initState() {
    super.initState();
    imageFile = widget.initialImageFile; // Define a imagem inicial (se houver)
    photoDate =
        widget.initialPhotoDate; // Define a data inicial da foto (se houver)
  }

  // Função para selecionar uma imagem da câmera ou galeria.
  Future<void> pick(ImageSource source) async {
    final XFile? pickedFile = await imagePicker.pickImage(source: source);

    if (pickedFile != null) {
      // Salva a imagem localmente no diretório da aplicação.
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(pickedFile.path);
      final String localPath = path.join(directory.path, fileName);
      final File localImage = await File(pickedFile.path).copy(localPath);

      // Atualiza o estado com a nova imagem e a data.
      setState(() {
        imageFile = localImage;
        photoDate = DateTime.now(); // Define a data atual
      });

      // Realiza o upload da imagem para o servidor.
      await uploadImage(localImage);
    }
  }

  // Função para fazer o upload da imagem para um servidor externo.
  Future<void> uploadImage(File image) async {
    final uri =
        Uri.parse('https://your-server-url.com/upload'); // URL do servidor
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();

    // Verifica se o upload foi bem-sucedido.
    if (response.statusCode == 200) {
      print('Image uploaded successfully');
    } else {
      print('Image upload failed with status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 5, // Elevação do card para dar um efeito de sombra.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Exibe a imagem selecionada, se houver.
                imageFile != null
                    ? Image.file(
                        imageFile!,
                        height: MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(),
                // Se a imagem for carregada, exibe o texto da data.
                imageFile != null
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Data da foto?',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : const SizedBox.shrink(),
                // Exibe uma área de informações sobre práticas da empresa.
                imageFile != null
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Informações sobre práticas da empresa? talvez colocar uns ícones aqui ou uma lista ou estrelas?',
                          style: TextStyle(fontSize: 14),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botão para abrir o modal que permite escolher entre câmera e galeria.
          ElevatedButton(
            onPressed: () {
              showMaterialModalBottomSheet(
                expand: false,
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => SingleChildScrollView(
                  controller: ModalScrollController.of(context),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Opção para abrir a câmera
                        ListTile(
                          leading: Icon(Icons.camera_alt),
                          title: Text('Camera'),
                          onTap: () {
                            pick(ImageSource.camera);
                            Navigator.pop(context);
                          },
                        ),
                        // Opção para abrir a galeria
                        ListTile(
                          leading: Icon(Icons.photo_library),
                          title: Text('Gallery'),
                          onTap: () {
                            pick(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                        ),
                        // Opção para cancelar
                        ListTile(
                          leading: Icon(Icons.cancel),
                          title: Text('Cancel'),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 5, // Elevação do botão quando pressionado.
            ),
            child: const Text('Imagem de input'),
          ),
        ],
      ),
    );
  }
}

// Função que exibe detalhes de uma imagem em um modal.
void showImageDetails(
    BuildContext context, File imageFile, DateTime photoDate) {
  showMaterialModalBottomSheet(
    expand: false,
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SingleChildScrollView(
      controller: ModalScrollController.of(context),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              elevation: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exibe a imagem selecionada em detalhes.
                  Image.file(
                    imageFile,
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.cover,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Data da foto?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Informações sobre práticas da empresa? talvez colocar uns ícones aqui ou uma lista ou estrelas?',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Página de histórico, onde o usuário pode ver as imagens salvas.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // Função que retorna as imagens salvas localmente.
  Future<List<File>> _getSavedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    return files.whereType<File>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<File>>(
        future: _getSavedImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator()); // Indicador de carregamento.
          } else if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading images')); // Mensagem de erro.
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No images found')); // Nenhuma imagem encontrada.
          } else {
            final images = snapshot.data!;
            // Exibe as imagens salvas em um grid.
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showImageDetails(
                      context,
                      images[index],
                      File(images[index].path).lastModifiedSync(),
                    );
                  },
                  child: Image.file(images[index]),
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// Página de configurações (ainda vazia).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Configure configurações'));
  }
}
