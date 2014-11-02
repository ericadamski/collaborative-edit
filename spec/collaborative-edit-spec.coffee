{WorkspaceView} = require 'atom'
CollaborativeEdit = require '../lib/collaborative-edit'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "CollaborativeEdit", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('collaborative-edit')

  describe "when the collaborative-edit:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.collaborative-edit')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'collaborative-edit:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.collaborative-edit')).toExist()
        atom.workspaceView.trigger 'collaborative-edit:toggle'
        expect(atom.workspaceView.find('.collaborative-edit')).not.toExist()
