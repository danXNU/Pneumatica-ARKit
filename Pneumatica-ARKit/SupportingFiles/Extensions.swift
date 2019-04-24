//
//  Extensions.swift
//  SFA
//
//  Created by Dani Tox on 14/11/2018.
//  Copyright © 2018 Dani Tox. All rights reserved.
//

import UIKit

extension UIDevice {
    var deviceType : UIUserInterfaceIdiom {
        return UIDevice.current.userInterfaceIdiom
    }
}

extension Notification.Name {
    static let updateTheme = Notification.Name("UPDATE_THEME")
}

extension String {
    var firstLine : String {
        if let line1 = self.components(separatedBy: .newlines).first {
            return line1
        } else {
            return self
        }
    }
    
    var wordsCount : Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { !$0.isEmpty }
        return words.count
    }
}

extension UIViewController {
    
    func showAlert(withTitle title: String, andMessage message : String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func enableAutoHideKeyboardAfterTouch(in views: [UIView]) {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        views.forEach({ $0.addGestureRecognizer(tap)})
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    var isInNavigationController : Bool {
        if let _ = self.navigationController {
            return true
        } else {
            return false
        }
    }
    
    var isRootNavigationPage : Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if nav.viewControllers.first == self {
            return true
        } else {
            return false
        }
    }
    
}

extension Date {
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    //    var noon: Date {
    //        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    //    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return tomorrow.month != month
    }
    
    func dayOfWeek() -> String {
        let dateF = DateFormatter()
        dateF.dateFormat = "EEEE"
        let dayEng = dateF.string(from: self).capitalized
        var dayIT : String
        switch dayEng {
        case "Monday":
            dayIT = "Lunedì"
        case "Tuesday":
            dayIT = "Martedì"
        case "Wednesday":
            dayIT = "Mercoledì"
        case "Thursday":
            dayIT = "Giovedì"
        case "Friday":
            dayIT = "Venerdì"
        case "Saturday":
            dayIT = "Sabato"
        case "Sunday":
            dayIT = "Domenica"
        default:
            dayIT = "ErroreGiorno: \(dayEng)"
        }
        return dayIT
    }
    
    var startOfWeek: Date? {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.locale = Locale(identifier: "it_IT")
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        return sunday //gregorian.date(byAdding: .day, value: 1, to: sunday)
    }
    
    var endOfWeek: Date? {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return nil }
        
        guard let nextSunday = gregorian.date(byAdding: .day, value: 7, to: sunday) else { return nil }
        let day = gregorian.component(.day, from: nextSunday)
        let month = gregorian.component(.month, from: nextSunday)
        let year = gregorian.component(.year, from: nextSunday)
        
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = 23
        components.minute = 59
        components.second = 59
        
        return gregorian.date(from: components)
    }
    
    enum WeekDays : Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }
    
    func next(weekday : WeekDays) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let nextDayComponents = DateComponents(calendar: calendar, weekday: weekday.rawValue)
        return calendar.nextDate(after: Date(), matching: nextDayComponents, matchingPolicy: .nextTimePreservingSmallerComponents)
    }
    
    func isToday() -> Bool {
        var calendar = Calendar.current
        calendar.locale = NSLocale.current
        
        let todayStart = calendar.startOfDay(for: Date())
        let givenDateStart = calendar.startOfDay(for: self)
        
        if todayStart == givenDateStart {
            return true
        } else {
            return false
        }
    }
    
    func isYesterday() -> Bool {
        var calendar = Calendar.current
        calendar.locale = NSLocale.current
        
        let todayStart = calendar.startOfDay(for: Date())
        let givenDateStart = calendar.startOfDay(for: self)
        
        guard let realYesterday =  calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return false
        }
        
        if realYesterday == givenDateStart {
            return true
        } else {
            return false
        }
    }
    
    var stringValue : String {
        var calendar = Calendar.current
        calendar.locale = NSLocale.current
        
        let day = calendar.component(.day, from: self)
        let month = calendar.component(.month, from: self)
        let year = calendar.component(.year, from: self)
    
        return "\(day)/\(month)/\(year)"
    }
    
    var startOfDay : Date {
        var calendar = Calendar.current
        calendar.locale = NSLocale.current
        
        return calendar.startOfDay(for: self)
    }
}


extension UIView {
    
    func fillSuperview() {
        anchor(top: superview?.topAnchor, leading: superview?.leadingAnchor, bottom: superview?.bottomAnchor, trailing: superview?.trailingAnchor)
    }
    
    func anchorSize(to view: UIView) {
        widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    func anchor(top: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, trailing: NSLayoutXAxisAnchor?, padding: UIEdgeInsets = .zero, size: CGSize = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: padding.top).isActive = true
        }
        
        if let leading = leading {
            leadingAnchor.constraint(equalTo: leading, constant: padding.left).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom).isActive = true
        }
        
        if let trailing = trailing {
            trailingAnchor.constraint(equalTo: trailing, constant: -padding.right).isActive = true
        }
        
        if size.width != 0 {
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }
        
        if size.height != 0 {
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }
}

extension UIColor {
    
    func lighter(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
}

struct Folders {
    static var documentsPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
}


