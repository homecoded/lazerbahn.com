<?php
declare(strict_types=1);

namespace Basecom\AdminUserRoles\Setup\Patch\Data;

use Magento\Authorization\Model\ResourceModel\Role\Collection as RulesCollection;
use Magento\Authorization\Model\Role;
use Magento\Authorization\Model\Rules;
use Magento\Framework\Setup\ModuleDataSetupInterface;
use Magento\Framework\Setup\Patch\DataPatchInterface;
use Magento\Framework\Setup\Patch\PatchRevertableInterface;
use Magento\Authorization\Model\ResourceModel\Role\CollectionFactory as RolesCollectionFactory;
use Magento\Authorization\Model\ResourceModel\Rules\CollectionFactory as RulesCollectionFactory;
use Magento\Authorization\Model\RulesFactory;

class EnablePagebuilderPermission implements DataPatchInterface, PatchRevertableInterface
{
    private const ADDITIONAL_REQUIRED_RESOURCES = [
        'Magento_PageBuilder::templates',
        'Magento_PageBuilder::template_save',
        'Magento_PageBuilder::template_apply',
        'Magento_PageBuilder::template_delete'
    ];

    public function __construct(
        private readonly ModuleDataSetupInterface $moduleDataSetup,
        private readonly RolesCollectionFactory $rolesCollectionFactory,
        private readonly RulesCollectionFactory $rulesCollectionFactory,
        private readonly RulesFactory $rulesFactory
    ) {
    }

    public function apply(): void
    {
        $this->moduleDataSetup->getConnection()->startSetup();
        $rolesCollection = $this->rolesCollectionFactory->create();
        $roles = $rolesCollection->getItems();

        /** @var Role $role */
        foreach ($roles as $role) {
            if ($role->getRoleName() === 'Administrators') {
                continue;
            }
            $newPermissions = $this->getExtendedPermissionListForRole($role);

            if (!empty($newPermissions)) {
                /** @var Rules $rule */
                $rule = $this->rulesFactory->create();
                $rule->setRoleId($role->getId());
                $rule->setData('resources', $newPermissions);
                $rule->saveRel();
            }
        }

        $this->moduleDataSetup->getConnection()->endSetup();
    }

    public static function getDependencies(): array
    {
        return [];
    }

    public function revert()
    {
    }

    public function getAliases(): array
    {
        return [];
    }

    protected function getExtendedPermissionListForRole(Role $role): array
    {
        /** @var RulesCollection $existingRules */
        $existingRules = $this->rulesCollectionFactory->create();
        $existingRules->getSelect()->where('role_id = ?', $role->getId());
        $existingRules->getSelect()->where('permission = ?', 'allow');
        $exitingItems = $existingRules->getItems();

        if (count($exitingItems) === 0) {
            return [];
        }

        $newPermissions = [];
        /** @var Rules $rule */
        foreach ($exitingItems as $rule) {
            $newPermissions[$rule->getResourceId()] = $rule->getResourceId();
        }

        foreach (self::ADDITIONAL_REQUIRED_RESOURCES as $newPermission) {
            $newPermissions[$newPermission] = $newPermission;
        }

        return array_values($newPermissions);
    }
}
