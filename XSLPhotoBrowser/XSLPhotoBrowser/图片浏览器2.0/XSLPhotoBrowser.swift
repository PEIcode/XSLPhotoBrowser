//
//  XSLPhotoBrowser.swift
//  Third-party-framework
//
//  Created by 廖佩志 on 2018/12/5.
//  Copyright © 2018 廖佩志. All rights reserved.
//

import UIKit

class XSLPhotoBrowser: UIViewController {
    /// 传入图片的index
    var pageIndex: Int = 0 {
        didSet {
            if pageIndex != oldValue {
                delegate.photoBrowser(self, pageIndexDidChanged: pageIndex)
            }
        }
    }
    /// 图片之间的间隔
    var photoSpacing: CGFloat = 30
    /// collectionView 数据源
    var dataSource: XSLPhotoBrowserBaseDataSource
    /// collectionView 代理
    var delegate: XSLPhotoBrowserBaseDelegate

    ///
    var transDelegate: XSLPhotoBrowserTransitioningDelegate {
        didSet {
            self.transitioningDelegate = transDelegate
        }
    }

    /// 返回正在执行转场动画的view
    var transitionZoomView: UIView? {
        return delegate.transitionZoomView(self, pageIndex: pageIndex)
    }
    /// 返回对应collectionViewCell的image
    var imageForCollectionViewCell: UIView? {
        return delegate.displayingContentView(self, pageIndex: pageIndex)
    }
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = photoSpacing
        layout.itemSize = view.bounds.size
        return layout
    }()
    lazy var collectionView: UICollectionView = {
        let collectionV = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionV.backgroundColor = UIColor.clear
        collectionV.showsVerticalScrollIndicator = false
        collectionV.showsHorizontalScrollIndicator = false
        collectionV.isPagingEnabled = true
        collectionV.alwaysBounceVertical = false
        collectionV.delegate = delegate
        collectionV.dataSource = dataSource
        collectionV.frame = view.bounds
        collectionV.frame.size.width = view.bounds.width + photoSpacing
        collectionV.contentInset = UIEdgeInsetsMake(0, 0, 0, photoSpacing)
//        collectionV.register(XSLBaseCollectionViewCell.self, forCellWithReuseIdentifier: "XSLBaseCollectionViewCell")
        return collectionV
    }()

    init(pageIndex: Int, dataSource: XSLPhotoBrowserBaseDataSource, deledate: XSLPhotoBrowserBaseDelegate = XSLPhotoBrowserDelegate(), transDelegate: XSLPhotoBrowserTransitioningDelegate = XSLPhotoBrowserFadeTransitioning()) {
        self.pageIndex = pageIndex
        self.dataSource = dataSource
        self.delegate = deledate
        self.transDelegate = transDelegate

        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transDelegate

        dataSource.browser = self
        deledate.browser = self
        transDelegate.browser = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        collectionView.reloadData()
        //注册不同的cell
        dataSource.registerCell(for: collectionView)
//        collectionView.scrollToItem(at: IndexPath(item: pageIndex, section: 0), at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
        scrollToItem(index: pageIndex, at: .left, animation: true)
        /// 强制刷新，才能在animateTransition()之前拿到colleCell的frame
        collectionView.layoutIfNeeded()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    /// 滑到哪张图片
    /// - parameter index: 图片序号，从0开始
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // 记录旋转前index
        let index = pageIndex
        DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration, execute: {
            self.scrollToItem(index: index, at: .left, animation: false)
        })
    }

    func scrollToItem(index: Int, at position: UICollectionView.ScrollPosition, animation: Bool) {
        var safeIndex = max(0, index)
        safeIndex = min(itemsCount - 1, safeIndex)
        let indexPath = IndexPath(item: safeIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: position, animated: animation)
    }
    /// 取项数
    open var itemsCount: Int {
        return dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
    }

    open func reloadData() {
        let numberOfItems = itemsCount
        guard numberOfItems > 0 else {
            delegate.dismissPhotoBrowser(self)
            return
        }
        pageIndex = min(pageIndex, numberOfItems - 1)
        collectionView.reloadData()
        delegate.photoBrowserDidReloadData(self)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate.photobrowser(self, viewDidLoad: animated)
    }
    deinit {
        print("XSLPhotoBrowser销毁")
    }
}
