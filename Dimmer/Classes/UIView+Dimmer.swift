//
//  UIView+Dimmer.swift
//  Pods
//
//  Created by DragonCherry on 5/12/17.
//
//

import UIKit
import TinyLog
import UIViewKVO
import FadeView
import PureLayout
import OptionalTypes

fileprivate let kDimmerView                             = "kDimmerView"
fileprivate let kDimmerViewRatio                        = "kDimmerViewRatio"
fileprivate let kDimmerActivityIndicatorView            = "kDimmerActivityIndicatorView"

fileprivate let kDimmerLayoutConstraints                = "kDimmerLayoutConstraints"
fileprivate let kDimmerWidthConstraint                  = "kDimmerWidthConstraint"
fileprivate let kDimmerHeightConstraint                 = "kDimmerHeightConstraint"

public enum DimmerEffectDirection {
    case solid
    case fromTop
    case fromLeft
    case fromBottom
    case fromRight
}

// MARK: - Internal Utilities
extension UIView {
    
    fileprivate var dimmerConstraints: NSArray? {
        set { set(newValue, forKey: kDimmerLayoutConstraints) }
        get { return get(kDimmerLayoutConstraints) as? NSArray }
    }
    
    fileprivate var dimmerWidthConstraint: NSLayoutConstraint? {
        set { set(newValue, forKey: kDimmerWidthConstraint) }
        get { return get(kDimmerWidthConstraint) as? NSLayoutConstraint }
    }
    
    fileprivate var dimmerHeightConstraint: NSLayoutConstraint? {
        set { set(newValue, forKey: kDimmerHeightConstraint) }
        get { return get(kDimmerHeightConstraint) as? NSLayoutConstraint }
    }
    
    fileprivate func setupConstraints(constraints: NSArray?) {
        dimmerConstraints?.autoRemoveConstraints()
        constraints?.autoInstallConstraints()
        dimmerConstraints = constraints
    }
    
    fileprivate func createDimmerView(alpha: CGFloat = 0.4) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = alpha
        return view
    }
    
    fileprivate func createDimmerActivityView(style: UIActivityIndicatorViewStyle = .gray) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: style)
        return activityIndicator
    }
    
    fileprivate func excludingEdge(with direction: DimmerEffectDirection) -> ALEdge {
        switch direction {
        case .fromTop:
            return .bottom
        case .fromLeft:
            return .right
        case .fromBottom:
            return .top
        case .fromRight:
            return .left
        case .solid:
            return .left
        }
    }
    
    fileprivate func clearKVO() {
        
        dimmerView?.removeFromSuperview()
        dimmerActivityView?.removeFromSuperview()
        
        dimmerConstraints = nil
        dimmerWidthConstraint = nil
        dimmerHeightConstraint = nil
        
        set(nil, forKey: kDimmerView)
        set(nil, forKey: kDimmerActivityIndicatorView)
        set(nil, forKey: kDimmerViewRatio)
    }
}

// MARK: - Exposed APIs
extension UIView {
    
    open var dimmingRatio: CGFloat {
        get { return CGFloat(get(kDimmerViewRatio)) }
        set { set(newValue, forKey: kDimmerViewRatio) }
    }
    open var isDimming: Bool {
        if let dimmerView = dimmerView, !dimmerView.isHidden && dimmingRatio > 0 {
            return true
        } else {
            return false
        }
    }
    
    open var isLoading: Bool {
        if let _ = get(kDimmerActivityIndicatorView), dimmingRatio > 0 {
            return true
        } else {
            return false
        }
    }
    
    open var dimmerView: UIView? {
        get { return get(kDimmerView) as? UIView }
        set {
            if let newDimmerView = newValue {
                if let oldDimmerView = dimmerView {
                    if oldDimmerView !== newDimmerView {
                        clearKVO()
                    }
                }
                set(newDimmerView, forKey: kDimmerView)
            } else {
                if let _ = dimmerView {
                    clearKVO()
                }
            }
        }
    }
    
    open var dimmerActivityView: UIView? {
        get { return get(kDimmerActivityIndicatorView) as? UIView }
        set {
            if let newDimmerActivityView = newValue {
                if let oldDimmerActivityView = dimmerActivityView {
                    if oldDimmerActivityView !== newDimmerActivityView {
                        clearKVO()
                    }
                }
                set(newDimmerActivityView, forKey: kDimmerActivityIndicatorView)
            } else {
                if let _ = dimmerActivityView {
                    clearKVO()
                }
            }
        }
    }
    
    open func dim(_ direction: DimmerEffectDirection = .solid, ratio: CGFloat = 1, alpha: CGFloat = 0.4, completion: ((CGFloat) -> Void)? = nil) {
        
        let updateRatio: (() -> Void) = {
            if self.dimmingRatio != ratio {
                switch direction {
                case .fromTop, .fromBottom:
                    self.dimmerHeightConstraint?.constant = self.frame.size.height * ratio
                case .fromLeft, .fromRight:
                    self.dimmerWidthConstraint?.constant = self.frame.size.width * ratio
                default:
                    break
                }
                self.dimmingRatio = ratio
            }
        }
        
        if let _ = self.dimmerView {
            updateRatio()
        } else {
            let dimmer = createDimmerView(alpha: alpha)
            fadeInSubview(dimmer)
            dimmerConstraints = NSLayoutConstraint.autoCreateConstraintsWithoutInstalling {
                if direction == .solid {
                    dimmer.autoPinEdgesToSuperviewEdges()
                } else {
                    dimmer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(), excludingEdge: self.excludingEdge(with: direction))
                    switch direction {
                    case .fromTop, .fromBottom:
                        dimmerHeightConstraint = dimmer.autoSetDimension(.height, toSize: self.frame.size.height * ratio)
                    case .fromLeft, .fromRight:
                        dimmerWidthConstraint = dimmer.autoSetDimension(.width, toSize: self.frame.size.width * ratio)
                    default:
                        break
                    }
                }
            } as NSArray
            dimmerView = dimmer
            setupConstraints(constraints: dimmerConstraints)
            updateRatio()
        }
    }
    
    open func undim() {
        dimmerView?.fadeOutFromSuperview(completion: {
            self.clearKVO()
        })
    }
    
    open func showLoading(alpha: CGFloat = 0.4, style: UIActivityIndicatorViewStyle = .gray) {
        dim(.solid, alpha: alpha)
        if let _ = self.dimmerActivityView {
            // already loading
        } else {
            let dimmerActivity = createDimmerActivityView(style: style)
            fadeInSubview(dimmerActivity)
            dimmerActivity.autoCenterInSuperview()
            dimmerActivity.startAnimating()
            dimmerActivityView = dimmerActivity
        }
    }
    
    open func hideLoading() {
        undim()
    }
}
