//
//  ViewController.swift
//  ArPoc
//
//  Created by Collin Hemeltjen on 19/11/2019.
//  Copyright © 2019 Collin Hemeltjen. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine

class ViewController: UIViewController {

	@IBOutlet var arView: ARView!
	let boxAnchor = try! Experience.loadBox()

	override func viewDidLoad() {
		super.viewDidLoad()
		addTapGestureToSceneView()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		enablePeopleOcclusion()
	}

	// adds a entity from a rcproject file
	func addVase(on anchor: float4x4) {
		guard let entity = boxAnchor.tulip?.clone(recursive: true) else {
			fatalError()
		}
		let anchorEntity = AnchorEntity(world: anchor)
		self.arView.scene.anchors.append(anchorEntity)

		anchorEntity.addChild(entity, preservingWorldTransform: false)
	}

	// a way to add a entity from a usdz file
	func addVaseDynamic(on anchor: float4x4) {
		var cancellable: AnyCancellable? = nil
		cancellable = ModelEntity.loadModelAsync(named: "vase")
			.sink(receiveCompletion: { error in
				print("Unexpected error: \(error)")
				cancellable?.cancel()
			}, receiveValue: { entity in
				let anchorEntity = AnchorEntity(world: anchor)
				self.arView.scene.anchors.append(anchorEntity)

				entity.scale = [1, 1, 1] * 0.006
				entity.generateCollisionShapes(recursive: true)
				anchorEntity.children.append(entity)
			})
	}

	func addTapGestureToSceneView() {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
		arView.addGestureRecognizer(tapGestureRecognizer)
	}

	@objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
		let tapLocation = recognizer.location(in: arView)

		guard let entity = arView.entity(at: tapLocation) else {
			let hitTestResultsWithFeaturePoints = arView.hitTest(tapLocation, types: .estimatedHorizontalPlane)
			if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
				addVase(on: hitTestResultWithFeaturePoints.worldTransform)
			}
			return
		}
		entity.removeFromParent()
	}

	func enablePeopleOcclusion(){
		guard ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) else {
			print("People occlusion is not supported on this device.")
			return
		}
		guard let config = arView.session.configuration else {
			fatalError("Unexpectedly failed to get the configuration.")
		}
		config.frameSemantics.insert(.personSegmentationWithDepth)
		arView.session.run(config)
	}
}
