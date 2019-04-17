//
//  IXSearchController.swift
//
//  A custom search controller that allow adding additional buttons to search bar, just like App Store on iPad.
//
//  Created by Isaac Chen on 2019/4/16.
//  Copyright © 2019 ix4n33. All rights reserved.
//
//  Known Issue:
//    - When `hidesNavigationBarDuringPresentation` is enabled, activate search bar for the
//      first time won't have a corrent animation. This may because of apple didn't use
//      search controller's view to animate. Didn't find a way to fix this yet, but a temporary
//      fix is available.
//    - When `hidesSearchBarWhenScrolling` set to `true`, there's some visual error first time scrolling up
//      after deactivated search bar.
//

import UIKit

class IXSearchController: UISearchController {
    
    // MARK: Public
    
    /// Bar buttons stack view on the left of search bar.
    let leftBarItemsStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [])
        view.axis = .horizontal
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Bar buttons stack view on the right of search bar.
    let rightBarItemsStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [])
        view.axis = .horizontal
        view.spacing = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Insert cancel button automatically.
    var autoInsertCancelButton = true
    
    /// Constraint search bar's max width on iPad. This option is ignored on non-iPad devices.
    var maxSearchBarWidthWhenActive: CGFloat? = nil
    
    /// Add extra spacing between stack view, this is ignored when `maxSearchBarWidthWhenActive` is `nil`. This option is ignored on non-iPad devices.
    var extraBarItemSpacing: CGFloat = 30
    
    var skipFirstTwoTransition: Bool = false
    
    // MARK: - Private
    
    private var _baseConstraints: [NSLayoutConstraint] = []
    private var _presentedConstraints: [NSLayoutConstraint] = []
    private var _dismissedConstraints: [NSLayoutConstraint] = []
    
    private var _topConstraint: NSLayoutConstraint?
    private var _bottomConstraint: NSLayoutConstraint?
    
    // temporary fix for a known issue.
    private var _firstEver: Bool = true
    
    private var barContainer: UIView? {
        return searchBar.subviews.first
    }
    
    private var searchField: UITextField? {
        return barContainer?.subviews.first(where: { $0.isKind(of: UITextField.self) }) as? UITextField
    }
    
    private var _extraBarItemSpacing: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad, let _ = maxSearchBarWidthWhenActive {
            return extraBarItemSpacing
        }
        return 0
    }
    
    // MARK: Cancel Button
    
    // private cancel button and its action
    private lazy var _cancelButton: UIButton = {
        let view = UIButton(type: .system)
        view.setAttributedTitle(NSAttributedString(string: NSLocalizedString("Cancel", comment: "Search bar cancel button"), attributes: [
            .font: UIFont.systemFont(ofSize: UIFont.buttonFontSize),
            .kern: -0.4
        ]), for: .normal)
        view.addTarget(self, action: #selector(_cancelButtonDown(_:)), for: .touchUpInside)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @objc private func _cancelButtonDown(_ sender: UIButton) {
        isActive = false
        searchBar.delegate?.searchBarCancelButtonClicked?(searchBar)
    }

}

// MARK:

extension IXSearchController {
    
    override var hidesNavigationBarDuringPresentation: Bool {
        didSet {
            _firstEver = !hidesNavigationBarDuringPresentation
        }
    }

     override func viewDidLoad() {
        super.viewDidLoad()
        guard let barContainer = barContainer, let searchField = searchField else { return }

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        // add subview
        barContainer.addSubview(leftBarItemsStack)
        barContainer.addSubview(rightBarItemsStack)
        updateCancelButtonInsertation()

        // setup constraints
        
        let (barH, fieldTop, fieldBottom) = constraintConstant(presented: false)
        
        _paletteHeightConstraint?.constant = barH
        _topConstraint = searchField.topAnchor.constraint(equalTo: barContainer.topAnchor, constant: fieldTop)
        _bottomConstraint = searchField.bottomAnchor.constraint(equalTo: barContainer.bottomAnchor, constant: fieldBottom).with(priority: .defaultHigh)
        
        _baseConstraints = [
            _topConstraint!,
            _bottomConstraint!,
            searchField.leadingAnchor.constraint(equalTo: barContainer.safeAreaLayoutGuide.leadingAnchor, constant: 20).with(priority: .defaultHigh),
            searchField.trailingAnchor.constraint(equalTo: barContainer.safeAreaLayoutGuide.trailingAnchor, constant: -20).with(priority: .defaultHigh),
            leftBarItemsStack.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            rightBarItemsStack.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
        ]

        let spacing = _extraBarItemSpacing

        _presentedConstraints = [
            leftBarItemsStack.leadingAnchor.constraint(equalTo: barContainer.safeAreaLayoutGuide.leadingAnchor, constant: spacing + 20),
            rightBarItemsStack.trailingAnchor.constraint(equalTo: barContainer.safeAreaLayoutGuide.trailingAnchor, constant: -(spacing + 20)),
            searchField.leadingAnchor.constraint(greaterThanOrEqualTo: leftBarItemsStack.trailingAnchor, constant: spacing + 16),
            searchField.trailingAnchor.constraint(lessThanOrEqualTo: rightBarItemsStack.leadingAnchor, constant: -(spacing + 16)),
        ]

        if UIDevice.current.userInterfaceIdiom == .pad, let width = maxSearchBarWidthWhenActive {
            _presentedConstraints.append(searchField.widthAnchor.constraint(lessThanOrEqualToConstant: width))
            _presentedConstraints.append(searchField.centerXAnchor.constraint(equalTo: barContainer.centerXAnchor).with(priority: .defaultHigh))
        }

        _dismissedConstraints = [
            leftBarItemsStack.trailingAnchor.constraint(equalTo: barContainer.leadingAnchor, constant: -20),
            rightBarItemsStack.leadingAnchor.constraint(equalTo: barContainer.trailingAnchor, constant: 20)
        ]

        NSLayoutConstraint.activate(_baseConstraints)
        NSLayoutConstraint.activate(_dismissedConstraints)
    }
    
}

// MARK: UIViewControllerAnimatedTransitioning

extension IXSearchController {
    
    private var _palette: UIView? {
        return searchBar.superview
    }
    
    private var _paletteHeightConstraint: NSLayoutConstraint? {
        return searchBar.superview?.constraints.first(where: {
            $0.firstItem?.isEqual(searchBar.superview!) ?? false && $0.firstAttribute == .height && $0.secondItem == nil
        })
    }
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let from = transitionContext.viewController(forKey: .from),
            let to = transitionContext.viewController(forKey: .to)
        else {
            super.animateTransition(using: transitionContext)
            return
        }
        
        let (barH, fieldTop, fieldBottom) = constraintConstant(presented: isActive)

        _paletteHeightConstraint?.constant = barH
        _topConstraint?.constant = fieldTop
        _bottomConstraint?.constant = fieldBottom
        
        if isActive {
            NSLayoutConstraint.deactivate(_dismissedConstraints)
            NSLayoutConstraint.activate(_presentedConstraints)

            // add search controller's view, where search result controller's view is presented.
            transitionContext.containerView.addSubview(to.view)
            to.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                to.view.topAnchor.constraint(equalTo: transitionContext.containerView.topAnchor),
                to.view.leadingAnchor.constraint(equalTo: transitionContext.containerView.leadingAnchor),
                to.view.trailingAnchor.constraint(equalTo: transitionContext.containerView.trailingAnchor),
                to.view.bottomAnchor.constraint(equalTo: transitionContext.containerView.bottomAnchor)
            ])
            
            to.view.setNeedsLayout()
        } else {
            NSLayoutConstraint.deactivate(_presentedConstraints)
            NSLayoutConstraint.activate(_dismissedConstraints)

            // remove search controller's view
            from.view.removeFromSuperview()
        }
        
        let duration = skipFirstTwoTransition && _firstEver ? 0.001 : transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut], animations: {
            self.barContainer?.layoutIfNeeded()
            self._palette?.superview?.layoutIfNeeded()
        }) {
            transitionContext.completeTransition($0)
            // some temporary fix
            if self.skipFirstTwoTransition && self._firstEver && from.isKind(of: IXSearchController.self) {
                self._firstEver = false
            }
        }
    }
    
    // when a rotation happend, system reset search field's frame to fill. override this to cancel that out.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animateAlongsideTransition(in: coordinator.containerView, animation: { _ in
            self.barContainer?.setNeedsLayout()
            self._palette?.superview?.layoutIfNeeded()
        })
    }
}

extension IXSearchController {
    
    private func updateCancelButtonInsertation() {
        if autoInsertCancelButton {
            if rightBarItemsStack.arrangedSubviews.contains(_cancelButton) {
                // check and move cancel button to last
                if !(rightBarItemsStack.arrangedSubviews.last?.isEqual(_cancelButton) ?? true) {
                    rightBarItemsStack.removeArrangedSubview(_cancelButton)
                    rightBarItemsStack.insertArrangedSubview(_cancelButton, at: rightBarItemsStack.arrangedSubviews.count)
                }
            } else {
                // insert cancel button
                rightBarItemsStack.insertArrangedSubview(_cancelButton, at: rightBarItemsStack.arrangedSubviews.count)
            }
        } else {
            // remove cancel button if needed
            if rightBarItemsStack.arrangedSubviews.contains(_cancelButton) {
                rightBarItemsStack.removeArrangedSubview(_cancelButton)
                _cancelButton.removeFromSuperview()
            }
        }
    }
    
    //
    // return corrent constant for constraints.
    // For some reason, apple decide to use different frame for different devices.
    //
    // When `hidesNavigationBarDuringPresentation = true`:
    //
    // |              | Portrait                                           | Landscape                                          |
    // |              | SearchBarHeight | SearchFieldHeight | SearchFieldY | SearchBarHeight | SearchFieldHeight | SearchFieldY |
    // | 5s, SE       | 50              | 36                | 4            | 44              | 30                | 7            |
    // | 6, 7, 8      | 50              | 36                | 4            | 44              | 30                | 7            |
    // | 6, 7, 8 Plus | 50              | 36                | 4            | 50              | 36                | 4 (7)        |
    // | X, XS        | 55              | 36                | 4            | 44              | 30                | 7            |
    // | XR           | 55              | 36                | 5            | 50              | 36                | 4 (7)        |
    // | XS Max       | 55              | 36                | 4            | 50              | 36                | 4 (7)        |
    // | iPad         | 50              | 36                | 7            | 44              | 30                | 7            |
    //
    // When `hidesNavigationBarDuringPresentation = false`:
    //
    // |              | Portrait                                           | Landscape                                          |
    // |              | SearchBarHeight | SearchFieldHeight | SearchFieldY | SearchBarHeight | SearchFieldHeight | SearchFieldY |
    // | 5s, SE       | 52              | 36                | 1            | 46              | 30                | 1            |
    // | 6, 7, 8      | 52              | 36                | 1            | 46              | 30                | 1            |
    // | 6, 7, 8 Plus | 52              | 36                | 1            | 52              | 36                | 1            |
    // | X, XS        | 52              | 36                | 1            | 46              | 30                | 1            |
    // | XR           | 52              | 36                | 1            | 52              | 36                | 1            |
    // | XS Max       | 52              | 36                | 1            | 52              | 36                | 1            |
    // | iPad         | 52              | 36                | 1            | 52              | 36                | 1            |
    //
    // |     inactive | 52              | 36                | 1            | 52              | 36                | 1            |
    //
    private func constraintConstant(presented: Bool) -> (CGFloat, CGFloat, CGFloat) {
        let barH: CGFloat
        let fieldH: CGFloat
        let fieldY: CGFloat
        
        if presented {
            let isLandscape = UIDevice.current.orientation.isLandscape
            
            if hidesNavigationBarDuringPresentation {
                switch UIDevice.current.userInterfaceIdiom {
                case .phone: // iPhone or iPod
                    let hasNotch = (UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0) > 0
                    
                    if isLandscape {
                        barH = UIScreen.main.bounds.height > 375 ? 50 : 44
                        fieldH = UIScreen.main.bounds.height > 375 ? 36 : 30
                        // 4 is not making search field vertically centered, this should be 7. Maybe this is apple's mistake?
                        //                    fieldY = UIScreen.main.bounds.width > 375 ? 4 : 7
                        fieldY = 7
                    } else {
                        let isXR = UIDevice.current.modelIdentifier == "iPhone11,8"
                        
                        barH = hasNotch ? 55 : 50
                        fieldH = 36
                        fieldY = isXR ? 5 : 4
                    }
                    
                default: // iPad
                    barH = 50
                    fieldH = 36
                    fieldY = 7
                }
            } else {
                if isLandscape {
                    if UIScreen.main.bounds.height > 375 {
                        barH = 52
                        fieldH = 36
                        fieldY = 1
                    } else {
                        barH = 46
                        fieldH = 30
                        fieldY = 1
                    }
                } else {
                    barH = 52
                    fieldH = 36
                    fieldY = 1
                }
            }
        } else {
            barH = 52
            fieldH = 36
            fieldY = 1
        }
        
        return (barH, fieldY, -(barH - fieldH - fieldY))
    }
    
}

// MARK: - Extensions

fileprivate extension NSLayoutConstraint {
    func with(priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }

    func with(priority: Float) -> NSLayoutConstraint {
        return with(priority: UILayoutPriority(rawValue: priority))
    }
}

fileprivate extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
