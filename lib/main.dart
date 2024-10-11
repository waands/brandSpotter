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
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            _pages[_selectedIndex],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.transparent, // Fundo transparente
                child: ResponsiveNavigationBar(
                  backgroundBlur: 0,
                  selectedIndex: _selectedIndex,
                  onTabChange: changeTab,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: const Color.fromARGB(255, 66, 66, 66),
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
                      icon: Icons.history,
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
            )
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
    try {
      print("pick method called with source: $source");

      final XFile? pickedFile = await imagePicker.pickImage(source: source);
      print("pickedFile: $pickedFile");

      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = path.basename(pickedFile.path);
        final String localPath = path.join(directory.path, fileName);
        final File localImage = await File(pickedFile.path).copy(localPath);

        setState(() {
          imageFile = localImage;
          photoDate = DateTime.now(); // Set the current date and time
        });

        print("Image exists: $imageFile");

        // Send the image to the remote server
        // await uploadImage(localImage);

        // Reload images to update the history
        await (context.findAncestorStateOfType<_HistoryPageState>())
            ?._loadImages();

        // Show image details in a modal
        showImageDetails(context, localImage, photoDate!);
      } else {
        print("No image selected");
      }
    } catch (e) {
      print("Error in pick method: $e");
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
    //String formattedDate = photoDate != null

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                            print("ei");
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
              shape: const CircleBorder(
                side: BorderSide(
                  color: Colors.cyan, // Cor da borda
                  width: 8.0, // Largura da borda
                ),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .document_scanner, //aqui a gente podia colocar nossa logo
                    color: Colors.cyan,
                    size: 100,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Analisar',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16.0)),
                    child: Image.file(
                      imageFile,
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
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
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  List<File> _images = []; // Lista para armazenar as imagens carregadas
  bool _isLoaded =
      false; // Variável para controlar se as imagens já foram carregadas

  // Função para obter as últimas 10 imagens salvas localmente
  Future<List<File>> _getSavedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();

    // Filtra apenas os arquivos de imagem
    List<File> images = files.whereType<File>().toList();

    // Filtra arquivos vazios
    images = images.where((file) => file.lengthSync() > 0).toList();

    // Ordena as imagens pela data de modificação (mais recentes primeiro)
    images.sort((a, b) {
      DateTime aModified = File(a.path).lastModifiedSync();
      DateTime bModified = File(b.path).lastModifiedSync();
      return bModified.compareTo(aModified);
    });

    // Retorna as últimas 10 imagens
    return images.take(10).toList();
  }

  // Função chamada quando o widget é inicializado
  @override
  void initState() {
    super.initState();
    _loadImages(); // Carrega as imagens ao iniciar
  }

  // Função para carregar as imagens do dispositivo (chamada uma vez)
  Future<void> _loadImages() async {
    if (!_isLoaded) {
      // Verifica se as imagens já foram carregadas
      try {
        final recentImages = await _getSavedImages();
        setState(() {
          _images = recentImages;
          _isLoaded = true; // Marca que as imagens já foram carregadas
        });
      } catch (e) {
        print('Error loading images: $e');
      }
    }
  }

  // Mantém o estado da página em cache quando ela não está visível
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para manter o estado
    return Scaffold(
      body: _images.isEmpty
          ? const Center(
              child: Text(
                  'Nenhuma logo analisada ainda...')) // Exibe se não houver imagens
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Quantidade de colunas
                crossAxisSpacing: 5.0, // Espaçamento horizontal
                mainAxisSpacing: 5.0, // Espaçamento vertical
              ),
              itemCount: _images.length, // Número de imagens a serem exibidas
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showImageDetails(
                      context,
                      _images[index],
                      File(_images[index].path).lastModifiedSync(),
                    );
                  },
                  child: Image.file(
                    _images[index],
                    fit: BoxFit.cover, // Faz a imagem se ajustar ao grid
                  ),
                );
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
