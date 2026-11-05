import Foundation
import Testing
@testable import Mariapp

struct ReceptesTests {
    /// Resposta recortada de TheMealDB (`lookup.php`): ingredients buits com "", " " i null, i CRLF a les instruccions.
    private let jsonDetall = """
    {"meals":[{
      "idMeal":"52771","strMeal":"Spicy Arrabiata Penne","strCategory":"Vegetarian","strArea":"Italian",
      "strInstructions":"Bring a large pot of water to a boil.\\r\\n\\r\\nAdd the penne.",
      "strMealThumb":"https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",
      "strYoutube":"https://www.youtube.com/watch?v=1IszT_guI08","strSource":"",
      "strIngredient1":"penne rigate","strIngredient2":"olive oil","strIngredient3":"garlic","strIngredient4":"",
      "strIngredient5":" ","strIngredient6":null,"strIngredient7":"chopped tomatoes","strIngredient8":"",
      "strMeasure1":"1 pound","strMeasure2":"1/4 cup","strMeasure3":"3 cloves","strMeasure4":"",
      "strMeasure5":" ","strMeasure6":null,"strMeasure7":"","strMeasure8":""
    }]}
    """.data(using: .utf8)!

    private let jsonResum = """
    {"meals":[
      {"idMeal":"1","strMeal":"Paella","strMealThumb":"https://www.themealdb.com/images/media/meals/a.jpg"},
      {"idMeal":"2","strMeal":"Tortilla","strMealThumb":"https://www.themealdb.com/images/media/meals/b.jpg"},
      {"strMeal":"Sense id"}
    ]}
    """.data(using: .utf8)!

    // MARK: Parseig

    @Test func parsejaUnDetallDescartantIngredientsBuits() throws {
        let r = try #require(ParserReceptes.parseja(jsonDetall).first)
        #expect(r.id == "52771")
        #expect(r.nom == "Spicy Arrabiata Penne")
        #expect(r.categoria == "Vegetarian")
        #expect(r.area == "Italian")
        #expect(r.ingredients.map(\.nom) == ["penne rigate", "olive oil", "garlic", "chopped tomatoes"])
        #expect(r.ingredients[0].mesura == "1 pound")
        #expect(r.ingredients[3].mesura == "")
        #expect(r.ingredients[0].text == "1 pound penne rigate")
        #expect(r.ingredients[3].text == "chopped tomatoes")
        #expect(r.imatge?.host == "www.themealdb.com")
        #expect(r.youtube != nil)
        // strSource buit → sense font.
        #expect(r.font == nil)
        #expect(!r.esResum)
    }

    @Test func instruccionsSenseSaltsDeLiniaDobles() throws {
        let r = try #require(ParserReceptes.parseja(jsonDetall).first)
        #expect(r.paragrafs == ["Bring a large pot of water to a boil.", "Add the penne."])
    }

    @Test func lesLlistesDeFilterSonResums() {
        let r = ParserReceptes.parseja(jsonResum)
        // La tercera no té id: es descarta.
        #expect(r.map(\.nom) == ["Paella", "Tortilla"])
        #expect(r.allSatisfy(\.esResum))
        #expect(r[0].imatge != nil)
    }

    @Test func mealsNullIJsonInvalidDonenLlistaBuida() {
        #expect(ParserReceptes.parseja(#"{"meals":null}"#.data(using: .utf8)!).isEmpty)
        #expect(ParserReceptes.parseja(Data("no és json".utf8)).isEmpty)
        #expect(ParserReceptes.parseja(Data()).isEmpty)
    }

    // MARK: ReceptaTraduida → Plat

    private func traduida() -> ReceptaTraduida {
        ReceptaTraduida(
            nom: "  Penne a l'arrabbiata ",
            emoji: "🍝",
            etiquetes: ["dinar", "RAPID", "inventada"],
            thermomix: true,
            ingredients: ["450 g de penne", " ", "Oli d'oliva"],
            passos: ["1. Bull l'aigua.", "Escorre la pasta.", ""]
        )
    }

    @Test func convertirEnPlatAmbFotoEnllacINotes() throws {
        let font = try #require(ParserReceptes.parseja(jsonDetall).first)
        let plat = traduida().comPlat(font: font)
        #expect(plat.nom == "Penne a l'arrabbiata")
        #expect(plat.emoji == "🍝")
        #expect(plat.etiquetes == [.dinar, .rapid])
        #expect(plat.thermomix)
        #expect(plat.ingredients.map(\.nom) == ["450 g de penne", "Oli d'oliva"])
        #expect(plat.ingredients.allSatisfy(\.tenim))
        #expect(plat.recepta == "1. Bull l'aigua.\n2. Escorre la pasta.")
        #expect(plat.imatgeURL == "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg")
        #expect(plat.urlImatge != nil)
        // Sense strSource, l'enllaç és el vídeo.
        #expect(plat.enllac == "https://www.youtube.com/watch?v=1IszT_guI08")
        #expect(plat.notes == "Recepta de TheMealDB (Italian)")
    }

    @Test func passosNoDuplicaLaNumeracio() {
        let r = ReceptaTraduida(nom: "X", passos: ["1) Un", "2. Dos", "3 - Tres", "2 cebes tallades"])
        #expect(r.passosNumerats == ["1. Un", "2. Dos", "3. Tres", "4. 2 cebes tallades"])
    }

    @Test func receptaInventadaPelaIASenseFont() {
        let plat = ReceptaTraduida(nom: "Truita de cigrons").comPlat()
        #expect(plat.imatgeURL == nil)
        #expect(plat.notes.contains("IA"))
        #expect(plat.emoji == "🍲")
    }

    @Test func guardarSenseTraduirConservaLAnglés() throws {
        let r = try #require(ParserReceptes.parseja(jsonDetall).first)
        let plat = r.comPlatSenseTraduir()
        #expect(plat.nom == "Spicy Arrabiata Penne")
        #expect(plat.ingredients.first?.nom == "1 pound penne rigate")
        #expect(plat.recepta.contains("Add the penne."))
        #expect(!plat.thermomix)
    }

    @Test func decodificaLaRespostaDeLaIAEncaraQueSeLiaplegueCamps() throws {
        let text = """
        Ací la tens!
        {"nom": "Crema de carabassa", "emoji": "🎃", "ingredients": ["500 g de carabassa"], "passos": ["Talla-la", "Cou-la"]}
        """
        let r = try #require(ServeiIA.decodifica(text, tipus: ReceptaTraduida.self))
        #expect(r.nom == "Crema de carabassa")
        #expect(r.etiquetes.isEmpty)
        #expect(r.thermomix == false)
        #expect(r.passos.count == 2)
    }

    @Test func decodificaUnaLlistaDePropostes() throws {
        let text = #"[{"nom":"A","thermomix":true},{"nom":"B"}]"#
        let r = try #require(ServeiIA.decodifica(text, tipus: [ReceptaTraduida].self))
        #expect(r.map(\.nom) == ["A", "B"])
        #expect(r[0].thermomix)
    }

    // MARK: Plat

    @Test func platAntiguSenseImatgeURLEsDecodifica() throws {
        let json: [String: Any] = ["nom": "Truita", "emoji": "🍳", "thermomix": false]
        let plat = try #require(Codificador.registre(Plat.self, id: "p1", dades: json))
        #expect(plat.imatgeURL == nil)
        #expect(plat.urlImatge == nil)
        #expect(plat.nom == "Truita")
    }

    @Test func imatgeURLFaViatgeIUnaURLInvalidaSIgnora() throws {
        var plat = Plat(nom: "Pasta")
        plat.imatgeURL = "https://example.com/pasta.jpg"
        let dades = Codificador.diccionari(plat)
        let torna = try #require(Codificador.registre(Plat.self, id: plat.id, dades: dades))
        #expect(torna.imatgeURL == "https://example.com/pasta.jpg")

        plat.imatgeURL = "no és una url"
        #expect(plat.urlImatge == nil)
        plat.imatgeURL = "ftp://example.com/a.jpg"
        #expect(plat.urlImatge == nil)
    }

    @Test func promptsMencionenThermomixSegonsLOpcio() {
        let r = ReceptaExterna(id: "1", nom: "Paella", instruccions: "Cook.", ingredients: [IngredientExtern(nom: "rice", mesura: "2 cups")])
        let tm = ServeiReceptes.promptTraduccio(r, thermomix: true)
        let normal = ServeiReceptes.promptTraduccio(r, thermomix: false)
        #expect(tm.contains("TM6"))
        #expect(!normal.contains("TM6"))
        #expect(tm.contains("2 cups rice"))
        let q = ServeiReceptes.promptIngredients(["pollastre", "cigrons"], thermomix: false)
        #expect(q.contains("pollastre, cigrons"))
    }
}
