part of 'main.dart';



// ==========================================
// FUNÇÕES AUXILIARES
// ==========================================
String formatarDuracao(Duration d) {
  if (d.inMinutes < 1) return '${d.inSeconds} s';
  if (d.inHours < 1) return '${d.inMinutes} min';
  return '${d.inHours} h ${d.inMinutes % 60} min';
}


String rotuloStatusOcorrencia(StatusOcorrencia s) => switch (s) {
      StatusOcorrencia.aberta => 'Aberta',
      StatusOcorrencia.emAndamento => 'Em andamento',
      StatusOcorrencia.resolvida => 'Resolvida',
    };


String rotuloPrioridade(PrioridadeOcorrencia p) => switch (p) {
      PrioridadeOcorrencia.baixa => 'Baixa',
      PrioridadeOcorrencia.media => 'Média',
      PrioridadeOcorrencia.alta => 'Alta',
    };
