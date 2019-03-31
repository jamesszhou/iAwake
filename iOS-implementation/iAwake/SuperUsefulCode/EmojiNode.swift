/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SceneKit

class EmojiNode: SCNNode {
  
  var options: [String]
  var index = 0
  
  init(with options: [String], width: CGFloat = 0.06, height: CGFloat = 0.06) {
    self.options = options
    
    super.init()
    
    let plane = SCNPlane(width: width, height: height)
    plane.firstMaterial?.diffuse.contents = (options.first ?? " ").image()
    plane.firstMaterial?.isDoubleSided = true
    
    geometry = plane
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Custom functions

extension EmojiNode {
  
  func updatePosition(for vectors: [vector_float3]) {
    let newPos = vectors.reduce(vector_float3(), +) / Float(vectors.count)
    position = SCNVector3(newPos)
  }
  
  func next() {
    index = (index + 1) % options.count
    
    if let plane = geometry as? SCNPlane {
      plane.firstMaterial?.diffuse.contents = options[index].image()
      plane.firstMaterial?.isDoubleSided = true
    }
  }
}
