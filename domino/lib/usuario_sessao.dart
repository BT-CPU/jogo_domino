class UsuarioSessao {
  const UsuarioSessao({
    required this.idUsuario,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  final int idUsuario;
  final String nome;
  final String email;
  final String perfil;
}
