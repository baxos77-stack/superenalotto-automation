import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sbdjhcrzlaztjmlrbnia.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNiZGpoY3J6bGF6dGptbHJibmlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE3MDY3NjUsImV4cCI6MjA5NzI4Mjc2NX0.Mri3eopvc8OOKFwR4ko8SxFn8b5KW47jBPUIWfbn6tg',
  );
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainScaffold()));
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _draws = [];
  bool _isLoading = true;
  String _analisiStatus = "Sistema pronto";
  String _analisiSpia = "In attesa...";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // FILTRO AVANZATO: Escludiamo categoricamente righe vuote o con zeri
      final response = await Supabase.instance.client
          .from('estrazioni')
          .select()
          .not('n1', 'is', null) // Niente valori nulli
          .gt('n1', 0)           // Niente zeri
          .order('data', ascending: false); // Ordine cronologico dal più recente
      
      _draws = List<Map<String, dynamic>>.from(response);
      _eseguiAnalisiAI();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Errore critico: $e");
      setState(() => _isLoading = false);
    }
  }

  void _eseguiAnalisiAI() {
    if (_draws.isEmpty) return;
    
    // Logica Spia
    int ultimoN1 = _draws[0]['n1'];
    Map<int, int> successori = {};
    for (int i = 1; i < _draws.length; i++) {
      if (_draws[i]['n1'] == ultimoN1) {
        int next = _draws[i-1]['n1'];
        successori[next] = (successori[next] ?? 0) + 1;
      }
    }
    int bestSpia = successori.entries.isNotEmpty 
        ? successori.entries.reduce((a, b) => a.value > b.value ? a : b).key 
        : 0;

    setState(() {
      _analisiSpia = "Il numero spia dopo $ultimoN1 è il $bestSpia";
      _analisiStatus = "Analisi completata su ${_draws.length} estrazioni verificate.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 XG-SuperStar Pro Suite'),
        backgroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.amber)) : _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black87,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.table_chart), label: 'Archivio Excel'),
          BottomNavigationBarItem(icon: Icon(Icons.science), label: 'AI Engine'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentIndex) {
      case 0: return _buildDashboard();
      case 1: return _buildExcelArchive();
      case 2: return _buildBacktest();
      default: return _buildDashboard();
    }
  }

  // DASHBOARD COMPLETA
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _buildInfoCard("STATO MOTORE AI", _analisiStatus, Colors.blue.shade900),
        const SizedBox(height: 16),
        _buildInfoCard("ANALISI NUMERI SPIA", _analisiSpia, Colors.deepPurple.shade900),
        const SizedBox(height: 16),
        _buildInfoCard("ULTIMA ESTRAZIONE VALIDA", 
          _draws.isNotEmpty ? "${_draws[0]['data']}:\n${_draws[0]['n1']} - ${_draws[0]['n2']} - ${_draws[0]['n3']} - ${_draws[0]['n4']} - ${_draws[0]['n5']} - ${_draws[0]['n6']}  (SS: ${_draws[0]['superstar']})" : "Dati non disponibili", 
          Colors.amber.shade900),
      ]),
    );
  }

  // ARCHIVIO TIPO EXCEL
  Widget _buildExcelArchive() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          border: TableBorder.all(color: Colors.grey.shade800),
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade900),
          columns: const [
            DataColumn(label: Text('Data', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('N1')),
            DataColumn(label: Text('N2')),
            DataColumn(label: Text('N3')),
            DataColumn(label: Text('N4')),
            DataColumn(label: Text('N5')),
            DataColumn(label: Text('N6')),
            DataColumn(label: Text('Jolly')),
            DataColumn(label: Text('Superstar', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
          ],
          rows: _draws.map((d) => DataRow(cells: [
            DataCell(Text(d['data']?.toString() ?? '')),
            DataCell(Text(d['n1']?.toString() ?? '')),
            DataCell(Text(d['n2']?.toString() ?? '')),
            DataCell(Text(d['n3']?.toString() ?? '')),
            DataCell(Text(d['n4']?.toString() ?? '')),
            DataCell(Text(d['n5']?.toString() ?? '')),
            DataCell(Text(d['n6']?.toString() ?? '')),
            DataCell(Text(d['jolly']?.toString() ?? '')),
            DataCell(Text(d['superstar']?.toString() ?? '', style: const TextStyle(color: Colors.amber))),
          ])).toList(),
        ),
      ),
    );
  }

  // BACKTEST / AI ENGINE
  Widget _buildBacktest() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Motore Analisi Predittiva", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {}, 
            child: const Text("Avvia Ottimizzazione AI (In sviluppo)", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          Container(
            height: 200, 
            decoration: BoxDecoration(color: Colors.black26, border: Border.all(color: Colors.white24)), 
            child: const Center(child: Text("Console di sistema pronta...", style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent)))
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 10),
        Text(content, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ])),
    );
  }
}