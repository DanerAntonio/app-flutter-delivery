import 'dart:math';

class ChristianMessage {
  final String message;
  final String verse;
  final String reference;

  ChristianMessage({
    required this.message,
    required this.verse,
    required this.reference,
  });
}

class ChristianMessages {
  static final List<ChristianMessage> _messages = [
    ChristianMessage(
      message: "Dios tiene planes de bien para ti",
      verse: "Porque yo sé los pensamientos que tengo acerca de vosotros, pensamientos de paz, y no de mal",
      reference: "Jeremías 29:11",
    ),
    ChristianMessage(
      message: "Él es tu fuerza en tiempos de debilidad",
      verse: "Mi gracia es suficiente para ti, porque mi poder se perfecciona en la debilidad",
      reference: "2 Corintios 12:9",
    ),
    ChristianMessage(
      message: "Él es tu refugio seguro",
      verse: "El Señor es mi luz y mi salvación; ¿a quién temeré?",
      reference: "Salmos 27:1",
    ),
    ChristianMessage(
      message: "Nunca estás solo",
      verse: "El Señor es mi pastor; nada me faltará",
      reference: "Salmos 23:1",
    ),
    ChristianMessage(
      message: "Que tengsa un día bendecido",
      verse: "El Señor te bendiga y te guarde; el Señor haga resplandecer su rostro sobre ti, y tenga de ti misericordia",
      reference: "Números 6:24-25",
    ),
    ChristianMessage(
      message: "De la Cocina de claudia",
      verse: "Que tengan un agradable almuerzo en familia",
      reference: "Claudia Cocina por ti",
    ),
    ChristianMessage(
      message: "Su amor nunca falla",
      verse: "Jehová tu Dios está en medio de ti, poderoso para salvar; se gozará sobre ti con alegría",
      reference: "Sofonías 3:17",
    ),
    ChristianMessage(
      message: "Jusucristo es tu fortaleza",
      verse: "Jesuscristo es la misma ayer, y hoy, y por los siglos",
      reference: "Hebreos 13:8",
    ),
    ChristianMessage(
      message: "Todo es posible con fe",
      verse: "Todo lo puedo en Cristo que me fortalece",
      reference: "Filipenses 4:13",
    ),
    ChristianMessage(
      message: "Él cuida de ti en todo momento",
      verse: "Echad toda vuestra ansiedad sobre él, porque él tiene cuidado de vosotros",
      reference: "1 Pedro 5:7",
    ),
    ChristianMessage(
      message: "Su gracia es suficiente para hoy",
      verse: "Bástate mi gracia; porque mi poder se perfecciona en la debilidad",
      reference: "2 Corintios 12:9",
    ),
    ChristianMessage(
      message: "Confía en su tiempo perfecto",
      verse: "Todo tiene su tiempo, y todo lo que se quiere debajo del cielo tiene su hora",
      reference: "Eclesiastés 3:1",
    ),
    ChristianMessage(
      message: "Eres amado incondicionalmente",
      verse: "Mas Dios muestra su amor para con nosotros, en que siendo aún pecadores, Cristo murió por nosotros",
      reference: "Romanos 5:8",
    ),
    ChristianMessage(
      message: "Él renueva tus fuerzas cada día",
      verse: "Pero los que esperan a Jehová tendrán nuevas fuerzas; levantarán alas como las águilas",
      reference: "Isaías 40:31",
    ),
    ChristianMessage(
      message: "Su paz sobrepasa todo entendimiento",
      verse: "Y la paz de Dios, que sobrepasa todo entendimiento, guardará vuestros corazones",
      reference: "Filipenses 4:7",
    ),
    ChristianMessage(
      message: "Él está contigo siempre",
      verse: "No te desampararé, ni te dejaré",
      reference: "Hebreos 13:5",
    ),
    ChristianMessage(
      message: "Cada día trae nuevas misericordias",
      verse: "Por la misericordia de Jehová no hemos sido consumidos, porque nunca decayeron sus misericordias",
      reference: "Lamentaciones 3:22",
    ),
    ChristianMessage(
      message: "Dios obra para tu bien",
      verse: "Y sabemos que a los que aman a Dios, todas las cosas les ayudan a bien",
      reference: "Romanos 8:28",
    ),
    ChristianMessage(
      message: "Su gozo es tu fortaleza",
      verse: "El gozo de Jehová es vuestra fuerza",
      reference: "Nehemías 8:10",
    ),
    ChristianMessage(
      message: "Eres una nueva creación",
      verse: "De modo que si alguno está en Cristo, nueva criatura es; las cosas viejas pasaron",
      reference: "2 Corintios 5:17",
    ),
    ChristianMessage(
      message: "Él tiene victoria preparada",
      verse: "Mas gracias sean dadas a Dios, que nos da la victoria por medio de nuestro Señor Jesucristo",
      reference: "1 Corintios 15:57",
    ),
    ChristianMessage(
      message: "Su amor es eterno",
      verse: "Jehová se manifestó a mí hace ya mucho tiempo, diciendo: Con amor eterno te he amado",
      reference: "Jeremías 31:3",
    ),
    ChristianMessage(
      message: "Él guía tus pasos",
      verse: "Por Jehová son ordenados los pasos del hombre, y él aprueba su camino",
      reference: "Salmos 37:23",
    ),
    ChristianMessage(
      message: "Su protección te rodea",
      verse: "Como Jerusalén tiene montes alrededor de ella, así Jehová está alrededor de su pueblo",
      reference: "Salmos 125:2",
    ),
    ChristianMessage(
      message: "Él sana tu corazón",
      verse: "Sana a los quebrantados de corazón, y venda sus heridas",
      reference: "Salmos 147:3",
    ),
    ChristianMessage(
      message: "Su palabra es lámpara",
      verse: "Lámpara es a mis pies tu palabra, y lumbrera a mi camino",
      reference: "Salmos 119:105",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "Ama a tu esposa/o y cuida de tu familia",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "No olvoides congreagarte con otros creyentes para insitar en la fe",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "Ora sin cesar, en todo momento habla con Dios",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "Da gracias en todo momento, por lo que tienes y por lo que eres",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De La cocina de Claudia",
      verse: "Perdona a los que te han hecho daño, así como Dios te perdona a ti",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "Lee las escrituras biblicas con responsabilidad pidiendo a Dios entendimiento",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "El dialogo entre familia es importante en mometos de crisis",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "En la unidad familiar esta la fuerza",
      reference: "Claudia te aconceja",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "acuerdate de tu Dios en los dias de tu juventud",
      reference: "eclesiastes 12:1",
    ),
    ChristianMessage(
      message: "De la cocina de Claudia",
      verse: "Honra a tu padre y a tu madre para que tus dias sean prolongados en la tierra y te vaya bien",
      reference: "exodo 20:12",
    ),
    
  ];

  static ChristianMessage getRandomMessage() {
    final random = Random();
    return _messages[random.nextInt(_messages.length)];
  }

  static ChristianMessage getMessageByIndex(int index) {
    return _messages[index % _messages.length];
  }

  static ChristianMessage getDailyMessage() {
    // Usar la fecha actual para generar un mensaje consistente durante el día
    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(1970, 1, 1)).inDays;
    return getMessageByIndex(daysSinceEpoch);
  }

  static List<ChristianMessage> getAllMessages() {
    return List.unmodifiable(_messages);
  }

  static int get messageCount => _messages.length;
}