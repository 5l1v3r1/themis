//
//  SMessageClient.swift
//  SwiftThemisServerExample
//
//  Created by Anastasi Voitova on 19.04.16.
//  Copyright © 2016 CossackLabs. All rights reserved.
//

import Foundation


final class SMessageClient {
    
    //
    //// user id and server public key are copied from server setup
    //// https://themis.cossacklabs.com/interactive-simulator/setup/
    //let kUserId: String = "<user id>"
    //let kServerPublicKey: String = "<server public key>"
    //
    //// these two should generated by running `generateClientKeys()`
    //let kClientPrivateKey: String = "<generated client private key>"
    //var kClientPublicKey: String = "<generated client public key>"
    //
    
    
    // user id and server public key are copied from server setup
    // https://themis.cossacklabs.com/interactive-simulator/setup/
    let kUserId: String = "ujuphCiLEAschmN"
    let kServerPublicKey: String = "<VUVDMgAAAC0MlT4yAmGxiZjXYFCFrEaSURQRH71W3ARSOIXpULrjPUY7X8Tn"
    
    // these two should generated by running `generateClientKeys()`
    let kClientPrivateKey: String = "UkVDMgAAAC1bQS8uAFJGunUpJ05UfWLW6goT5ZqPvM6RwLo+5Ig/BWY+n7dV"
    let kClientPublicKey: String = "VUVDMgAAAC2Fyt5xAmPEHHxqP1vu1Y2WF4HpFve0tMJAA0G12pQndgxtXBVk"
    

    private func postRequestTo(stringURL: String, message: NSData, completion: (data: NSData?, error: NSError?) -> Void) {
        let url: NSURL = NSURL(string: stringURL)!
        let config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session: NSURLSession = NSURLSession(configuration: config)
        
        let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        
        let base64URLEncodedMessage: String = message.base64EncodedStringWithOptions(.EncodingEndLineWithLineFeed).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        let base64Body: String = "\("message=")\(base64URLEncodedMessage)"
        let body: NSData = base64Body.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let uploadTask: NSURLSessionDataTask = session.uploadTaskWithRequest(request, fromData: body,
                completionHandler: {(data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                    
            guard let data = data else {
                print("Oops, response = \(response)\n error = \(error)")
                completion(data: nil, error: error)
                return
            }
                
            if let response = response as? NSHTTPURLResponse where response.statusCode != 200 {
                print("Oops, response = \(response)\n error = \(error)")
                completion(data: nil, error: error)
                return
            }
                    
            completion(data: data, error: nil)
            return
        })
        
        uploadTask.resume()
    }


    func runSecureMessageCITest() {
        // uncomment to generate keys firste
        // generateClientKeys()
        // return;
        
        
        checkKeysNotEmpty()
        
        guard let serverPublicKey: NSData = NSData(base64EncodedString: kServerPublicKey,
                                                   options: .IgnoreUnknownCharacters),
            let clientPrivateKey: NSData = NSData(base64EncodedString: kClientPrivateKey,
                                                  options: .IgnoreUnknownCharacters) else {
                                                    
            print("Error occurred during base64 encoding", #function)
            return
        }
        
        let encrypter: TSMessage = TSMessage.init(inEncryptModeWithPrivateKey: clientPrivateKey,
                                                  peerPublicKey: serverPublicKey)
        
        let message: String = "Hello Themis from Swift! Testing your server here ;)"
        
        var encryptedMessage: NSData = NSData()
        do {
            encryptedMessage = try encrypter.wrapData(message.dataUsingEncoding(NSUTF8StringEncoding))
            print("encryptedMessage = \(encryptedMessage)")
            
        } catch let error as NSError {
            print("Error occurred while encrypting \(error)", #function)
            return
        }
        
        let stringURL: String = "\("https://themis.cossacklabs.com/api/")\(kUserId)/"
        postRequestTo(stringURL, message: encryptedMessage, completion: {(data: NSData?, error: NSError?) -> Void in
            guard let data = data else {
                print("response error \(error)")
                return
            }        
            
            do {
                let decryptedMessage: NSData = try encrypter.unwrapData(data)
                let resultString: String = String(data: decryptedMessage, encoding: NSUTF8StringEncoding)!
                print("decryptedMessage->\n\(resultString)")
                
            } catch let error as NSError {
                print("Error occurred while decrypting \(error)", #function)
                return
            }
        })
    }

    private func generateClientKeys() {
        // use client public key to run server
        // https://themis.cossacklabs.com/interactive-simulator/setup/
        //
        // use client private key to encrypt your message
        
        guard let keyGeneratorEC: TSKeyGen = TSKeyGen(algorithm: .EC) else {
            print("Error occurred while initializing object keyGeneratorEC", #function)
            return
        }
        let privateKeyEC: NSData = keyGeneratorEC.privateKey
        let publicKeyEC: NSData = keyGeneratorEC.publicKey
        
        print("EC privateKey = \(privateKeyEC.base64EncodedDataWithOptions(.Encoding64CharacterLineLength))")
        print("RSA publicKey = \(publicKeyEC.base64EncodedDataWithOptions(.Encoding64CharacterLineLength))")
    }


    private func checkKeysNotEmpty() {
        assert(!(kUserId == "<user id>"), "Get user id from https://themis.cossacklabs.com/interactive-simulator/setup/")
        assert(!(kServerPublicKey == "<server public key>"), "Get server key from https://themis.cossacklabs.com/interactive-simulator/setup/")
        assert(!(kClientPrivateKey == "<generated client private key>"), "Generate client keys by running `generateClientKeys()` or obtain from server https://themis.cossacklabs.com/interactive-simulator/setup/")
        assert(!(kClientPublicKey == "<generated client public key>"), "Generate client keys by running `generateClientKeys()` or obtain from server https://themis.cossacklabs.com/interactive-simulator/setup/")
    }
}