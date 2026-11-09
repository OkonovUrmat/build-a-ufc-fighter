import Foundation
import GoatDomain

/// Curated launch roster of UFC legends across all 12 divisions.
///
/// IMPORTANT: attribute ratings are subjective expert-style estimates based on
/// each fighter's historical peak — they are NOT official UFC data.
/// Professional records are approximate and must be verified when the full
/// database is built in Phase 2 (active fighters' records change).
///
/// Rating order in `r`: striking, power, kicking, wrestling, groundGame,
///                      speed, chin, cardio, fightIQ, size
/// SIZE is rated relative to the fighter's own division (frame, reach, strength).
public enum SampleFighterCatalog {
    public static let fighters: [Fighter] = [
        // MARK: Flyweight
        make("demetrious-johnson", "Demetrious Johnson", "Mighty Mouse", .us, .flyweight, (30, 4, 1, 0),
             [90, 72, 85, 95, 93, 97, 88, 97, 99, 70]),
        make("joseph-benavidez", "Joseph Benavidez", "Joe-B", .us, .flyweight, (28, 8, 0, 0),
             [84, 80, 78, 86, 88, 90, 86, 88, 87, 66]),
        make("deiveson-figueiredo", "Deiveson Figueiredo", "Deus da Guerra", .br, .flyweight, (24, 5, 1, 0),
             [84, 92, 78, 78, 88, 85, 84, 76, 80, 82]),

        // MARK: Bantamweight
        make("dominick-cruz", "Dominick Cruz", "The Dominator", .us, .bantamweight, (24, 4, 0, 0),
             [89, 68, 78, 88, 78, 96, 84, 92, 96, 80]),
        make("merab-dvalishvili", "Merab Dvalishvili", "The Machine", .ge, .bantamweight, (20, 5, 0, 0),
             [76, 66, 72, 98, 82, 87, 90, 100, 90, 74]),
        make("petr-yan", "Petr Yan", "No Mercy", .ru, .bantamweight, (20, 5, 0, 0),
             [93, 86, 84, 84, 80, 85, 92, 90, 93, 82]),
        make("sean-omalley", "Sean O'Malley", "Suga", .us, .bantamweight, (18, 3, 0, 1),
             [92, 90, 89, 62, 66, 90, 82, 80, 85, 92]),

        // MARK: Featherweight
        make("jose-aldo", "José Aldo", "The King of Rio", .br, .featherweight, (32, 9, 0, 0),
             [94, 88, 97, 86, 82, 92, 90, 82, 92, 80]),
        make("alexander-volkanovski", "Alexander Volkanovski", "The Great", .au, .featherweight, (27, 4, 0, 0),
             [93, 82, 86, 88, 82, 88, 88, 96, 97, 70]),
        make("max-holloway", "Max Holloway", "Blessed", .us, .featherweight, (27, 8, 0, 0),
             [96, 84, 84, 78, 80, 88, 99, 99, 92, 82]),
        make("ilia-topuria", "Ilia Topuria", "El Matador", .es, .featherweight, (17, 0, 0, 0),
             [94, 97, 78, 84, 88, 88, 92, 88, 93, 72]),

        // MARK: Lightweight
        make("khabib-nurmagomedov", "Khabib Nurmagomedov", "The Eagle", .ru, .lightweight, (29, 0, 0, 0),
             [78, 78, 62, 100, 98, 82, 92, 97, 95, 86]),
        make("charles-oliveira", "Charles Oliveira", "do Bronx", .br, .lightweight, (35, 11, 0, 1),
             [84, 86, 86, 78, 99, 82, 76, 88, 85, 88]),
        make("islam-makhachev", "Islam Makhachev", nil, .ru, .lightweight, (28, 1, 0, 0),
             [86, 82, 84, 97, 97, 84, 88, 94, 95, 84]),
        make("dustin-poirier", "Dustin Poirier", "The Diamond", .us, .lightweight, (30, 10, 0, 1),
             [92, 92, 76, 76, 82, 84, 88, 90, 88, 82]),

        // MARK: Welterweight
        make("georges-st-pierre", "Georges St-Pierre", "Rush", .ca, .welterweight, (26, 2, 0, 0),
             [89, 80, 88, 99, 90, 90, 88, 96, 99, 86]),
        make("kamaru-usman", "Kamaru Usman", "The Nigerian Nightmare", .ng, .welterweight, (21, 4, 0, 0),
             [85, 88, 72, 95, 80, 84, 90, 95, 88, 90]),
        make("matt-hughes", "Matt Hughes", nil, .us, .welterweight, (45, 9, 0, 0),
             [70, 82, 60, 96, 90, 80, 84, 90, 84, 84]),

        // MARK: Middleweight
        make("anderson-silva", "Anderson Silva", "The Spider", .br, .middleweight, (34, 11, 0, 1),
             [99, 92, 94, 70, 84, 95, 82, 82, 97, 88]),
        make("israel-adesanya", "Israel Adesanya", "The Last Stylebender", .nz, .middleweight, (24, 6, 0, 0),
             [97, 82, 92, 68, 62, 93, 84, 88, 95, 92]),
        make("robert-whittaker", "Robert Whittaker", "The Reaper", .au, .middleweight, (27, 9, 0, 0),
             [90, 84, 86, 80, 76, 92, 86, 90, 90, 82]),

        // MARK: Light Heavyweight
        make("jon-jones", "Jon Jones", "Bones", .us, .lightHeavyweight, (28, 1, 0, 1),
             [92, 86, 92, 96, 94, 86, 92, 94, 99, 99]),
        make("daniel-cormier", "Daniel Cormier", "DC", .us, .lightHeavyweight, (22, 3, 0, 1),
             [84, 84, 70, 99, 86, 82, 88, 92, 92, 68]),
        make("alex-pereira", "Alex Pereira", "Poatan", .br, .lightHeavyweight, (13, 3, 0, 0),
             [96, 99, 92, 66, 64, 80, 88, 78, 86, 94]),
        make("chuck-liddell", "Chuck Liddell", "The Iceman", .us, .lightHeavyweight, (21, 9, 0, 0),
             [88, 94, 74, 82, 66, 80, 86, 80, 80, 84]),

        // MARK: Heavyweight
        make("francis-ngannou", "Francis Ngannou", "The Predator", .cm, .heavyweight, (18, 3, 0, 0),
             [84, 100, 62, 76, 68, 84, 92, 74, 80, 97]),
        make("stipe-miocic", "Stipe Miocic", nil, .us, .heavyweight, (20, 5, 0, 0),
             [89, 90, 72, 86, 82, 82, 88, 92, 92, 88]),
        make("cain-velasquez", "Cain Velasquez", nil, .us, .heavyweight, (14, 3, 0, 0),
             [86, 86, 70, 94, 84, 88, 82, 100, 88, 82]),

        // MARK: Women's Strawweight
        make("joanna-jedrzejczyk", "Joanna Jędrzejczyk", "Joanna Champion", .pl, .womensStrawweight, (16, 5, 0, 0),
             [93, 74, 90, 74, 66, 92, 84, 96, 90, 84]),
        make("zhang-weili", "Zhang Weili", "Magnum", .cn, .womensStrawweight, (25, 4, 0, 0),
             [90, 90, 82, 86, 84, 88, 92, 90, 88, 80]),
        make("rose-namajunas", "Rose Namajunas", "Thug", .us, .womensStrawweight, (14, 7, 0, 0),
             [88, 76, 84, 76, 82, 90, 80, 88, 88, 80]),

        // MARK: Women's Flyweight
        make("valentina-shevchenko", "Valentina Shevchenko", "Bullet", .kg, .womensFlyweight, (25, 4, 1, 0),
             [94, 82, 94, 86, 88, 90, 90, 92, 98, 80]),
        make("alexa-grasso", "Alexa Grasso", nil, .mx, .womensFlyweight, (16, 5, 1, 0),
             [86, 82, 74, 74, 86, 84, 84, 84, 84, 78]),

        // MARK: Women's Bantamweight
        make("amanda-nunes", "Amanda Nunes", "The Lioness", .br, .womensBantamweight, (23, 5, 0, 0),
             [92, 97, 82, 88, 88, 86, 84, 82, 90, 90]),
        make("ronda-rousey", "Ronda Rousey", "Rowdy", .us, .womensBantamweight, (12, 2, 0, 0),
             [66, 72, 50, 96, 98, 82, 68, 82, 72, 82]),
        make("holly-holm", "Holly Holm", "The Preacher's Daughter", .us, .womensBantamweight, (15, 7, 0, 0),
             [88, 78, 93, 72, 64, 82, 84, 88, 86, 84]),

        // MARK: Women's Featherweight
        make("cris-cyborg", "Cris Cyborg", nil, .br, .womensFeatherweight, (28, 2, 0, 1),
             [92, 95, 82, 82, 80, 84, 90, 88, 84, 92]),
        make("germaine-de-randamie", "Germaine de Randamie", "The Iron Lady", .nl, .womensFeatherweight, (10, 4, 0, 0),
             [88, 84, 86, 66, 62, 80, 84, 80, 84, 86]),
    ]

    private static func make(
        _ id: String,
        _ name: String,
        _ nickname: String?,
        _ nationality: Nationality,
        _ weightClass: WeightClass,
        _ record: (wins: Int, losses: Int, draws: Int, noContests: Int),
        _ r: [Int]
    ) -> Fighter {
        precondition(r.count == FighterAttribute.allCases.count, "\(id): expected 10 ratings")
        return Fighter(
            id: id,
            name: name,
            nickname: nickname,
            nationality: nationality,
            weightClass: weightClass,
            record: FighterRecord(wins: record.wins, losses: record.losses, draws: record.draws, noContests: record.noContests),
            attributes: FighterAttributes(
                striking: r[0], power: r[1], kicking: r[2], wrestling: r[3], groundGame: r[4],
                speed: r[5], chin: r[6], cardio: r[7], fightIQ: r[8], size: r[9]
            )
        )
    }
}

extension Nationality {
    static let us = Nationality(name: "United States", isoCode: "US")
    static let br = Nationality(name: "Brazil", isoCode: "BR")
    static let ru = Nationality(name: "Russia", isoCode: "RU")
    static let ge = Nationality(name: "Georgia", isoCode: "GE")
    static let au = Nationality(name: "Australia", isoCode: "AU")
    static let es = Nationality(name: "Spain", isoCode: "ES")
    static let ca = Nationality(name: "Canada", isoCode: "CA")
    static let ng = Nationality(name: "Nigeria", isoCode: "NG")
    static let nz = Nationality(name: "New Zealand", isoCode: "NZ")
    static let cm = Nationality(name: "Cameroon", isoCode: "CM")
    static let pl = Nationality(name: "Poland", isoCode: "PL")
    static let cn = Nationality(name: "China", isoCode: "CN")
    static let kg = Nationality(name: "Kyrgyzstan", isoCode: "KG")
    static let mx = Nationality(name: "Mexico", isoCode: "MX")
    static let nl = Nationality(name: "Netherlands", isoCode: "NL")
}
