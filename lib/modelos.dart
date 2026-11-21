part of 'main.dart';


// ==========================================
// MODELOS DE DADOS COM SERIALIZAÇÃO FIRESTORE
// ==========================================

enum TipoTarefa { reposicao, limpeza }

enum StatusTarefa { pendente, concluida, atrasada }

enum TipoPerfil { funcionario, gestor }

enum StatusOcorrencia { aberta, emAndamento, resolvida }

enum PrioridadeOcorrencia { baixa, media, alta }


class ModeloRonda {
  final String id, titulo, localNome, codigoQr, idResponsavel;
  final double? latitudeLocal, longitudeLocal;
  final TipoTarefa tipo;
  final int hora, minuto;
  final List<int> dias; // 1 = segunda ... 7 = domingo
  final List<String> checklist;
  bool ativo;
  String? ultimaGeracao;

  ModeloRonda({
    required this.id, required this.titulo, required this.localNome, required this.codigoQr,
    required this.idResponsavel, required this.tipo, required this.hora, required this.minuto,
    required this.dias, required this.checklist,
    this.latitudeLocal, this.longitudeLocal, this.ativo = true, this.ultimaGeracao,
  });

  Map<String, dynamic> toMap() => {
        'titulo': titulo, 'localNome': localNome, 'codigoQr': codigoQr, 'idResponsavel': idResponsavel,
        'latitudeLocal': latitudeLocal, 'longitudeLocal': longitudeLocal, 'tipo': tipo.name,
        'hora': hora, 'minuto': minuto, 'dias': dias, 'checklist': checklist,
        'ativo': ativo, 'ultimaGeracao': ultimaGeracao,
      };

  factory ModeloRonda.fromMap(Map<String, dynamic> m, String docId) => ModeloRonda(
        id: docId,
        titulo: m['titulo'] ?? '',
        localNome: m['localNome'] ?? '',
        codigoQr: m['codigoQr'] ?? '',
        idResponsavel: m['idResponsavel'] ?? '',
        latitudeLocal: (m['latitudeLocal'] as num?)?.toDouble(),
        longitudeLocal: (m['longitudeLocal'] as num?)?.toDouble(),
        tipo: m['tipo'] == 'limpeza' ? TipoTarefa.limpeza : TipoTarefa.reposicao,
        hora: (m['hora'] as num?)?.toInt() ?? 8,
        minuto: (m['minuto'] as num?)?.toInt() ?? 0,
        dias: (m['dias'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        checklist: (m['checklist'] as List?)?.map((e) => e.toString()).toList() ?? [],
        ativo: m['ativo'] ?? true,
        ultimaGeracao: m['ultimaGeracao'],
      );
}


class Local {
  final String id;
  final String nome;
  final String codigoQr;
  final double? latitude;
  final double? longitude;

  Local({required this.id, required this.nome, required this.codigoQr, this.latitude, this.longitude});

  Map<String, dynamic> toMap() => {'nome': nome, 'codigoQr': codigoQr, 'latitude': latitude, 'longitude': longitude};

  factory Local.fromMap(Map<String, dynamic> m, String docId) => Local(
        id: docId,
        nome: m['nome'] ?? '',
        codigoQr: m['codigoQr'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
      );
}


class Usuario {
  final String id;
  final String nome;
  final String username;
  final String senha;
  final TipoPerfil tipo;
  final String? fotoPath;
  final bool ativo;
  final String? consentimentoEm;

  Usuario({
    required this.id,
    required this.nome,
    required this.username,
    required this.senha,
    required this.tipo,
    this.fotoPath,
    this.ativo = true,
    this.consentimentoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'username': username,
      'senha': senha,
      'tipo': tipo.name,
      'fotoPath': fotoPath,
      'ativo': ativo,
      'consentimentoEm': consentimentoEm,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, String docId) {
    return Usuario(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      nome: map['nome'] ?? '',
      username: map['username'] ?? '',
      senha: map['senha'] ?? '',
      tipo: map['tipo'] == 'gestor' ? TipoPerfil.gestor : TipoPerfil.funcionario,
      fotoPath: map['fotoPath'],
      ativo: map['ativo'] ?? true,
      consentimentoEm: map['consentimentoEm'],
    );
  }
}


class ItemChecklist {
  final String titulo;
  bool concluido;

  ItemChecklist({required this.titulo, this.concluido = false});

  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'concluido': concluido,
  };

  factory ItemChecklist.fromMap(Map<String, dynamic> map) => ItemChecklist(
    titulo: map['titulo'] ?? '',
    concluido: map['concluido'] ?? false,
  );
}


class Tarefa {
  final String id;
  final String titulo;
  final String local;
  final String qrCodeEsperado;
  final TipoTarefa tipo;
  final DateTime horarioPrevisto;
  final String idResponsavel;
  StatusTarefa status;
  List<ItemChecklist> checklist;
  String? observacao;
  String? fotoAntesPath;
  String? fotoDepoisPath;
  bool produtoEmFalta;
  DateTime? horarioConclusao;
  double? latitudeCheckin;
  double? longitudeCheckin;
  double? latitudeLocal;
  double? longitudeLocal;
  String? idModelo;
  DateTime? horarioInicio;

  /// Tempo entre o check-in (QR validado) e a conclusão.
  Duration? get duracao => (horarioInicio != null && horarioConclusao != null) ? horarioConclusao!.difference(horarioInicio!) : null;

  /// Pendente com horário já vencido vira "atrasada" automaticamente.
  StatusTarefa get statusEfetivo =>
      (status == StatusTarefa.pendente && horarioPrevisto.isBefore(DateTime.now())) ? StatusTarefa.atrasada : status;

  Tarefa({
    required this.id,
    required this.titulo,
    required this.local,
    required this.qrCodeEsperado,
    required this.tipo,
    required this.horarioPrevisto,
    required this.idResponsavel,
    required this.checklist,
    this.status = StatusTarefa.pendente,
    this.fotoAntesPath,
    this.fotoDepoisPath,
    this.produtoEmFalta = false,
    this.observacao,
    this.horarioConclusao,
    this.latitudeCheckin,
    this.longitudeCheckin,
    this.latitudeLocal,
    this.longitudeLocal,
    this.idModelo,
    this.horarioInicio,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'local': local,
      'qrCodeEsperado': qrCodeEsperado,
      'tipo': tipo.name,
      'horarioPrevisto': horarioPrevisto.toIso8601String(),
      'idResponsavel': idResponsavel,
      'status': status.name,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'observacao': observacao,
      'fotoAntesPath': fotoAntesPath,
      'fotoDepoisPath': fotoDepoisPath,
      'produtoEmFalta': produtoEmFalta,
      'horarioConclusao': horarioConclusao?.toIso8601String(),
      'latitudeCheckin': latitudeCheckin,
      'longitudeCheckin': longitudeCheckin,
      'latitudeLocal': latitudeLocal,
      'longitudeLocal': longitudeLocal,
      'idModelo': idModelo,
      'horarioInicio': horarioInicio?.toIso8601String(),
    };
  }

  factory Tarefa.fromMap(Map<String, dynamic> map, String docId) {
    return Tarefa(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      titulo: map['titulo'] ?? '',
      local: map['local'] ?? '',
      qrCodeEsperado: map['qrCodeEsperado'] ?? '',
      tipo: map['tipo'] == 'limpeza' ? TipoTarefa.limpeza : TipoTarefa.reposicao,
      horarioPrevisto: map['horarioPrevisto'] != null ? DateTime.parse(map['horarioPrevisto']) : DateTime.now(),
      idResponsavel: map['idResponsavel'] ?? '',
      status: StatusTarefa.values.firstWhere(
            (s) => s.name == map['status'],
        orElse: () => StatusTarefa.pendente,
      ),
      checklist: (map['checklist'] as List<dynamic>?)
          ?.map((item) => ItemChecklist.fromMap(item))
          .toList() ??
          [],
      observacao: map['observacao'],
      fotoAntesPath: map['fotoAntesPath'],
      fotoDepoisPath: map['fotoDepoisPath'],
      produtoEmFalta: map['produtoEmFalta'] ?? false,
      horarioConclusao: map['horarioConclusao'] != null ? DateTime.parse(map['horarioConclusao']) : null,
      latitudeCheckin: (map['latitudeCheckin'] as num?)?.toDouble(),
      longitudeCheckin: (map['longitudeCheckin'] as num?)?.toDouble(),
      latitudeLocal: (map['latitudeLocal'] as num?)?.toDouble(),
      longitudeLocal: (map['longitudeLocal'] as num?)?.toDouble(),
      idModelo: map['idModelo'],
      horarioInicio: map['horarioInicio'] != null ? DateTime.parse(map['horarioInicio']) : null,
    );
  }
}


class Ocorrencia {
  final String id;
  final String titulo;
  final String descricao;
  final String local;
  final String autorNome;
  final String idAutor;
  final String? fotoPath;
  final PrioridadeOcorrencia prioridade;
  final String? idTarefa;
  final String? tarefaTitulo;
  StatusOcorrencia status;
  final DateTime dataAbertura;

  Ocorrencia({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.local,
    required this.autorNome,
    this.idAutor = '',
    this.fotoPath,
    this.prioridade = PrioridadeOcorrencia.media,
    this.idTarefa,
    this.tarefaTitulo,
    this.status = StatusOcorrencia.aberta,
    required this.dataAbertura,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'descricao': descricao,
    'local': local,
    'autorNome': autorNome,
    'idAutor': idAutor,
    'fotoPath': fotoPath,
    'prioridade': prioridade.name,
    'idTarefa': idTarefa,
    'tarefaTitulo': tarefaTitulo,
    'status': status.name,
    'dataAbertura': dataAbertura.toIso8601String(),
  };

  factory Ocorrencia.fromMap(Map<String, dynamic> map, String docId) => Ocorrencia(
    id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
    titulo: map['titulo'] ?? '',
    descricao: map['descricao'] ?? '',
    local: map['local'] ?? '',
    autorNome: map['autorNome'] ?? '',
    idAutor: map['idAutor'] ?? '',
    fotoPath: map['fotoPath'],
    prioridade: PrioridadeOcorrencia.values.firstWhere((p) => p.name == map['prioridade'], orElse: () => PrioridadeOcorrencia.media),
    idTarefa: map['idTarefa'],
    tarefaTitulo: map['tarefaTitulo'],
    status: StatusOcorrencia.values.firstWhere((s) => s.name == map['status'], orElse: () => StatusOcorrencia.aberta),
    dataAbertura: map['dataAbertura'] != null ? DateTime.parse(map['dataAbertura']) : DateTime.now(),
  );
}


class Aviso {
  final String id;
  final String titulo;
  final String mensagem;
  final DateTime data;
  final String autor;

  Aviso({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.data,
    required this.autor,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'mensagem': mensagem,
    'data': data.toIso8601String(),
    'autor': autor,
  };

  factory Aviso.fromMap(Map<String, dynamic> map, String docId) => Aviso(
    id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
    titulo: map['titulo'] ?? '',
    mensagem: map['mensagem'] ?? '',
    data: map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
    autor: map['autor'] ?? '',
  );
}


class NotificacaoUsuario {
  final String id;
  final String idUsuario;
  final String titulo;
  final String mensagem;
  final DateTime data;
  bool lida;

  NotificacaoUsuario({
    required this.id,
    required this.idUsuario,
    required this.titulo,
    required this.mensagem,
    required this.data,
    this.lida = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'idUsuario': idUsuario,
    'titulo': titulo,
    'mensagem': mensagem,
    'data': data.toIso8601String(),
    'lida': lida,
  };

  factory NotificacaoUsuario.fromMap(Map<String, dynamic> map, String docId) => NotificacaoUsuario(
    id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
    idUsuario: map['idUsuario'] ?? '',
    titulo: map['titulo'] ?? '',
    mensagem: map['mensagem'] ?? '',
    data: map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
    lida: map['lida'] ?? false,
  );
}
