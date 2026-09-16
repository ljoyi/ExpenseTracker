import Foundation

struct DefaultCategorySeed: Equatable, Sendable {
    let name: String
    let kind: TransactionKind
    let iconName: String
    let colorHex: String
    let sortOrder: Int

    static let all: [DefaultCategorySeed] = [
        DefaultCategorySeed(name: "三餐", kind: .expense, iconName: "fork.knife", colorHex: "#E76F51", sortOrder: 10),
        DefaultCategorySeed(name: "零食", kind: .expense, iconName: "takeoutbag.and.cup.and.straw.fill", colorHex: "#F4A261", sortOrder: 20),
        DefaultCategorySeed(name: "衣服", kind: .expense, iconName: "tshirt.fill", colorHex: "#E9C46A", sortOrder: 30),
        DefaultCategorySeed(name: "交通", kind: .expense, iconName: "bus.fill", colorHex: "#2A9D8F", sortOrder: 40),
        DefaultCategorySeed(name: "旅行", kind: .expense, iconName: "airplane", colorHex: "#00A8E8", sortOrder: 50),
        DefaultCategorySeed(name: "孩子", kind: .expense, iconName: "figure.and.child.holdinghands", colorHex: "#F15BB5", sortOrder: 60),
        DefaultCategorySeed(name: "宠物", kind: .expense, iconName: "pawprint.fill", colorHex: "#9B5DE5", sortOrder: 70),
        DefaultCategorySeed(name: "话费网费", kind: .expense, iconName: "wifi", colorHex: "#457B9D", sortOrder: 80),
        DefaultCategorySeed(name: "烟酒", kind: .expense, iconName: "wineglass.fill", colorHex: "#B56576", sortOrder: 90),
        DefaultCategorySeed(name: "学习", kind: .expense, iconName: "book.fill", colorHex: "#6D597A", sortOrder: 100),
        DefaultCategorySeed(name: "日用品", kind: .expense, iconName: "basket.fill", colorHex: "#43AA8B", sortOrder: 110),
        DefaultCategorySeed(name: "住房", kind: .expense, iconName: "house.fill", colorHex: "#577590", sortOrder: 120),
        DefaultCategorySeed(name: "美妆", kind: .expense, iconName: "sparkles", colorHex: "#FF70A6", sortOrder: 130),
        DefaultCategorySeed(name: "医疗", kind: .expense, iconName: "cross.case.fill", colorHex: "#E63946", sortOrder: 140),
        DefaultCategorySeed(name: "发红包", kind: .expense, iconName: "envelope.fill", colorHex: "#F94144", sortOrder: 150),
        DefaultCategorySeed(name: "汽车/加油", kind: .expense, iconName: "fuelpump.fill", colorHex: "#264653", sortOrder: 160),
        DefaultCategorySeed(name: "娱乐", kind: .expense, iconName: "gamecontroller.fill", colorHex: "#8338EC", sortOrder: 170),
        DefaultCategorySeed(name: "请客送礼", kind: .expense, iconName: "gift.fill", colorHex: "#FF6B6B", sortOrder: 180),
        DefaultCategorySeed(name: "电器数码", kind: .expense, iconName: "desktopcomputer", colorHex: "#3A86FF", sortOrder: 190),
        DefaultCategorySeed(name: "运动", kind: .expense, iconName: "figure.run", colorHex: "#06D6A0", sortOrder: 200),
        DefaultCategorySeed(name: "水电煤", kind: .expense, iconName: "bolt.fill", colorHex: "#FFB703", sortOrder: 210),
        DefaultCategorySeed(name: "其它", kind: .expense, iconName: "ellipsis.circle.fill", colorHex: "#6C757D", sortOrder: 220),
        DefaultCategorySeed(name: "工资", kind: .income, iconName: "banknote.fill", colorHex: "#2A9D8F", sortOrder: 10),
        DefaultCategorySeed(name: "生活费", kind: .income, iconName: "creditcard.fill", colorHex: "#457B9D", sortOrder: 20),
        DefaultCategorySeed(name: "收红包", kind: .income, iconName: "envelope.open.fill", colorHex: "#E76F51", sortOrder: 30),
        DefaultCategorySeed(name: "外快", kind: .income, iconName: "briefcase.fill", colorHex: "#F4A261", sortOrder: 40),
        DefaultCategorySeed(name: "股票基金", kind: .income, iconName: "chart.line.uptrend.xyaxis", colorHex: "#43AA8B", sortOrder: 50),
        DefaultCategorySeed(name: "其它", kind: .income, iconName: "ellipsis.circle.fill", colorHex: "#6C757D", sortOrder: 60)
    ]
}
