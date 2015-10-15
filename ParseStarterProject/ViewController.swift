/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var signupButton: UIButton!
    
    var signupState = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.username.delegate = self
        self.password.delegate = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (PFUser.currentUser()?.username != nil) {
            let segueType = (PFUser.currentUser()!["isDriver"] as! Bool) ? "LoginDriverSegue" : "LoginRiderSegue"
            self.performSegueWithIdentifier(segueType, sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signUp(sender: AnyObject) {
        if username.text!.isEmpty || password.text!.isEmpty {
            self.displayAlert("Error", message: "Username or password is empty please fill in values")
        } else {
            if signupState {
                let user: PFUser = PFUser()
                user.username = username.text
                user.password = password.text
                user["isDriver"] = `switch`.on
                
                user.signUpInBackgroundWithBlock() { (succeeded: Bool, error: NSError?) -> Void in
                    if let error = error {
                        let errorString = error.userInfo["error"] as? String
                        self.displayAlert("error", message: "error signing up")
                        print("Error \(errorString)")
                    } else {
                        let segueType = self.`switch`.on ? "LoginDriverSegue" : "LoginRiderSegue"
//                        if ((user["isDriver"] as? Bool) == true) {
//                            self.performSegueWithIdentifier("LoginDriverSegue", sender: self)
//                        } else {
//                            self.performSegueWithIdentifier("LoginRiderSegue", sender: self)
//                        }
                        self.performSegueWithIdentifier(segueType, sender: self)
                    }
                }
            } else {
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!) { (user: PFUser?, error: NSError?) -> Void in
                    if user != nil {
                        print(user)
                        let segueType = (user!["isDriver"] as! Bool) ? "LoginDriverSegue" : "LoginRiderSegue"
//                        if ((user["isDriver"] as? Bool) == true) {
//                            self.performSegueWithIdentifier("LoginDriverSegue", sender: self)
//                        } else {
//                            self.performSegueWithIdentifier("LoginRiderSegue", sender: self)
//                        }
                        self.performSegueWithIdentifier(segueType, sender: self)
                    } else {
                        let errorString = error!.userInfo["error"] as? String
                        self.displayAlert("error", message: "error signing up")
                        print("Error \(errorString)")
                    }
                }
            }
            
        }
    }
    
    @IBAction func toggleSignup(sender: AnyObject) {
        if signupState {
            signupButton.setTitle("Log In", forState: UIControlState.Normal)
            toggleSignupButton.setTitle("Switch to Signup", forState: .Normal)
            signupState = false
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
        } else {
            signupButton.setTitle("Signup", forState: UIControlState.Normal)
            toggleSignupButton.setTitle("Switch to Login", forState: .Normal)
            signupState = true
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
        }
    }
    @IBOutlet weak var toggleSignupButton: UIButton!
    
    func displayAlert(title: String, message: String) {
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
            let alert = UIAlertView(title: "username or password blank", message: "username and password cannot be black", delegate: nil, cancelButtonTitle: nil)
            alert.show()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Navigation
    
}
